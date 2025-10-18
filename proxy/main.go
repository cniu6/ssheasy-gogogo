package main

import (
	"bytes"
	"context"
	"embed"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"golang.org/x/net/websocket"
	"golang.org/x/time/rate"
)

//go:embed html
var embeddedFiles embed.FS

// 全局配置
var (
	debugMode     bool
	auditLog      *os.File
	auditLogMutex sync.Mutex
)

func main() {
	// 从环境变量读取配置
	debugMode = getEnvBool("DEBUG", false)

	publicAddr := flag.String("pub", getEnvString("PUBLIC_ADDR", ":5555"), "listener address")
	port := flag.Int("port", getEnvInt("PORT", 5555), "listener port (shorthand for -pub)")
	auditLogFile := flag.String("al", getEnvString("AUDIT_LOG_FILE", "connections.log"), "log file to store connection request, if empty connection logging is disabled")
	debugFlag := flag.Bool("debug", false, "enable debug mode for detailed logging")
	flag.Parse()

	// 处理debug参数
	if *debugFlag {
		debugMode = true
	}

	// 如果指定了port参数，优先使用
	if *port != 5555 {
		*publicAddr = fmt.Sprintf(":%d", *port)
	}

	if *publicAddr == "" {
		flag.PrintDefaults()
		os.Exit(1)
	}

	if auditLogFile != nil {
		var err error
		auditLog, err = os.OpenFile(*auditLogFile, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0600)
		if err != nil {
			log.Fatalf("failed to open connection log file %s: %v", *auditLogFile, err)
		}
	}

	wmux := websocket.Server{
		Handshake: bootHandshake,
		Handler:   handleWss,
	}

	r := mux.NewRouter()
	r.Handle("/ws", wmux)

	// 使用内嵌的文件系统
	htmlFS, err := fs.Sub(embeddedFiles, "html")
	if err != nil {
		log.Fatalf("failed to get embedded files: %v", err)
	}
	// 创建带缓存控制的文件服务器
	fileServer := http.FileServer(http.FS(htmlFS))
	cacheHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// 为静态资源添加缓存头
		if isStaticAsset(r.URL.Path) {
			w.Header().Set("Cache-Control", "public, max-age=3600") // 缓存1小时
			w.Header().Set("Expires", time.Now().Add(time.Hour).Format(http.TimeFormat))
		}
		fileServer.ServeHTTP(w, r)
	})
	r.PathPrefix("/cl/").Handler(http.StripPrefix("/cl", cacheHandler))

	srv := http.Server{
		Addr:    *publicAddr,
		Handler: r,
	}
	idleConnsClosed := make(chan struct{})
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, os.Interrupt)
		<-sigint

		if err := srv.Shutdown(context.Background()); err != nil {
			log.Printf("HTTP server Shutdown: %v", err)
		}
		close(idleConnsClosed)
	}()

	log.Printf("server starts on: %s", *publicAddr)
	if debugMode {
		log.Printf("debug mode enabled")
	} else {
		log.Printf("debug mode disabled")
	}
	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		log.Fatalf("HTTP server ListenAndServe: %v", err)
	}

	<-idleConnsClosed
	wc := 0
	for {
		a := atomic.LoadInt64(&activeWebsocks)
		if a <= 0 {
			log.Printf("%d active websockets, terminating", a)
			break
		}
		time.Sleep(300 * time.Millisecond)
		wc++
		if wc%100 == 0 {
			log.Printf("%d websockets are active, waiting", a)
		}
	}
}

var activeWebsocks int64

// isStaticAsset 判断是否为静态资源文件
func isStaticAsset(path string) bool {
	extensions := []string{".css", ".js", ".png", ".jpg", ".jpeg", ".gif", ".ico", ".svg", ".woff", ".woff2", ".ttf", ".eot", ".wasm"}
	for _, ext := range extensions {
		if strings.HasSuffix(strings.ToLower(path), ext) {
			return true
		}
	}
	return false
}

func handleWss(wsconn *websocket.Conn) {
	defer func() {
		atomic.AddInt64(&activeWebsocks, -1)
		wsconn.Close()
	}()
	atomic.AddInt64(&activeWebsocks, 1)
	id := wsconn.Config().Header.Get(reqIDHdr)
	l := logFromID(id)
	l.logf("request headers: %v", wsconn.Request().Header)
	blocked, ips := getIPAdress(wsconn)
	if blocked {
		l.logf("blocking ip: %v", ips)
		return
	}
	l.logf("handlewss from %v", ips)
	err := wsconn.SetReadDeadline(time.Now().Add(2 * time.Second))
	if err != nil {
		log.Printf("failed to set red deadline: %v", err)
		return
	}
	buf := make([]byte, 2048)
	_, err = wsconn.Read(buf)
	if err != nil {
		l.logf("failed to read connection msg: %v", err)
		return
	}
	var cr struct {
		Host string
		Port int
	}
	err = json.NewDecoder(bytes.NewBuffer(buf)).Decode(&cr)
	if err != nil {
		l.logf("failed to decode connection request [%s]: %v", buf, err)
		return
	}
	err = wsconn.SetReadDeadline(time.Time{})
	if err != nil {
		l.logf("failed to reset connection deadline: %v", err)
		return
	}
	l.logf("connecting to %s on port %d", cr.Host, cr.Port)
	writeAuditLog(ips[0], cr.Host, cr.Port, "connection request")
	if !isAllowedTarger(cr.Host) {
		l.logf("WARNING: connecting to %s is not allowed", cr.Host)
		return
	}
	var resp struct {
		Status string `json:"status"`
		Error  string `json:"error,omitempty"`
	}
	conn, err := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", cr.Host, cr.Port), 30*time.Second)
	if err != nil {
		l.logf("failed to connect: %v", err)
		writeAuditLog(ips[0], cr.Host, cr.Port, "connection failed")
		resp.Status = "failed"
		resp.Error = err.Error()
		if r, err := json.Marshal(resp); err != nil {
			l.logf("failed to marshall: %v", err)
		} else {
			if err := websocket.Message.Send(wsconn, r); err != nil {
				l.logf("failed to write status: %v", err)
			}
		}
		return
	}
	defer conn.Close()
	resp.Status = "ok"
	if r, err := json.Marshal(resp); err != nil {
		l.logf("failed to marshall: %v", err)
	} else {
		if err := websocket.Message.Send(wsconn, r); err != nil {
			l.logf("failed to write status: %v", err)
		}
	}
	writeAuditLog(ips[0], cr.Host, cr.Port, "connection established")
	wsconn.PayloadType = websocket.BinaryFrame

	cw, wsw := newLimters(conn, wsconn, l)

	done := make(chan struct{})

	go ping(l, wsconn, done)

	type conStat struct {
		dir   string
		err   error
		bytes int64
	}

	stats := make(chan conStat)

	go func() {
		n, err := io.Copy(cw, wsconn)
		conn.Close()
		stats <- conStat{"up", err, n}
	}()
	go func() {
		n, err := io.Copy(wsw, conn)
		wsconn.Close()
		stats <- conStat{"down", err, n}
	}()

	s1 := <-stats
	s2 := <-stats
	if s1.dir == "up" {
		l.logf("proxy finished copied (%d/%d)bytes anyerrors (%v,%v)", s1.bytes, s2.bytes, s1.err, s2.err)
		writeAuditLog(ips[0], cr.Host, cr.Port, fmt.Sprintf("proxy finished copied (%d/%d)bytes anyerrors (%v,%v)", s1.bytes, s2.bytes, s1.err, s2.err))
	} else {
		l.logf("proxy finished copied (%d/%d)bytes anyerrors (%v,%v)", s2.bytes, s1.bytes, s2.err, s1.err)
		writeAuditLog(ips[0], cr.Host, cr.Port, fmt.Sprintf("proxy finished copied (%d/%d)bytes anyerrors (%v,%v)", s2.bytes, s1.bytes, s2.err, s1.err))
	}
	close(done)
}

func writeAuditLog(srcIP, dstIP string, dstPort int, msg string) {
	if auditLog == nil {
		return
	}
	auditLogMutex.Lock()
	defer auditLogMutex.Unlock()
	_, err := auditLog.Write([]byte(fmt.Sprintf("%s,%s,%s,%d,%s\n", time.Now().UTC().Format(time.RFC3339Nano), srcIP, dstIP, dstPort, msg)))
	if err != nil {
		log.Printf("failed to write into connection log: %v", err)
	}
}

func ping(l logger, ws *websocket.Conn, done chan struct{}) {
	w, err := ws.NewFrameWriter(websocket.PingFrame)
	if err != nil {
		l.logf("failed to create pingwriter: %v", err)
		return
	}
	ticker := time.Tick(20 * time.Second)
	for {
		select {
		case <-ticker:
			_, err = w.Write(nil)
			if err != nil {
				l.logf("failed to write ping msg: %v", err)
				return
			}
		case <-done:
			return
		}
	}
}

type rCtx struct {
	headers http.Header
}

const reqIDHdr = "X-Request-ID"

func bootHandshake(config *websocket.Config, r *http.Request) error {
	// config.Protocol = []string{"binary"}
	u, err := uuid.NewRandom()
	id := "not-uuid"
	if err == nil {
		id = u.String()
	}
	config.Header = make(http.Header)
	config.Header.Set(reqIDHdr, id)

	// r.Header.Set("Access-Control-Allow-Origin", "*")
	// r.Header.Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE")

	return nil
}

var (
	blacklistedSources []string
	blacklistSrcMu     sync.RWMutex
	sourceRates        = map[string]*rate.Limiter{}
)

func getIPAdress(ws *websocket.Conn) (bool, []string) {
	// using sprintf as it panics locally
	var ips []string
	for _, h := range []string{"X-Forwarded-For", "X-Real-Ip"} {
		addresses := strings.Split(ws.Request().Header.Get(h), ",")
		for i := len(addresses) - 1; i >= 0; i-- {
			ip := strings.TrimSpace(addresses[i])

			ips = append(ips, ip)
		}
	}
	ips = append(ips, fmt.Sprintf("%v", ws.RemoteAddr()))
	blacklistSrcMu.RLock()
	defer blacklistSrcMu.RUnlock()
	if sourceRates[ips[0]] == nil {
		sourceRates[ips[0]] = rate.NewLimiter(rate.Limit(1), 1)
	}
	for _, bi := range blacklistedSources {
		for _, ip := range ips {
			if strings.HasPrefix(ip, bi) {
				return true, ips
			}
		}
	}
	return !sourceRates[ips[0]].Allow(), ips
}

var (
	blacklistedTargets = []string{"localhost", "127.0.0.1", "::1"}
	// blacklistedTargets = []string{}
	blacklistMu sync.RWMutex
)

func isAllowedTarger(host string) bool {
	blacklistMu.RLock()
	for _, h := range blacklistedTargets {
		if host == h {
			return false
		}
	}
	blacklistMu.RUnlock()

	return true
}

var (
	freeLimit                 = 1024 * 1024 * 1024
	maxLimitedRate rate.Limit = 100 * 1024
	maxBurst                  = 64 * 1024
)

func newLimters(w1, w2 io.Writer, logger logger) (*limitedWriter, *limitedWriter) {
	l := rate.NewLimiter(maxLimitedRate, maxBurst)
	return &limitedWriter{w: w1, limiter: l, log: logger}, &limitedWriter{w: w2, limiter: l, log: logger}
}

type limitedWriter struct {
	w       io.Writer
	written int
	limiter *rate.Limiter
	log     logger
}

func (w *limitedWriter) Write(b []byte) (n int, err error) {
	if w.written > freeLimit {
		if err := w.limiter.WaitN(context.Background(), len(b)); err != nil {
			w.log.logf("limiter wait error: %v", err)
		}
	}
	w.written += len(b)
	return w.w.Write(b)
}

type logger string

func (l logger) logf(fmt string, args ...interface{}) {
	if debugMode {
		log.Printf(string(l)+fmt, args...)
	}
}

func newLogger() logger {
	u, err := uuid.NewRandom()
	id := "not-uuid"
	if err == nil {
		id = u.String()
	}
	return logFromID(id)
}

func logFromID(id string) logger {
	if len(id) == 0 {
		return logger("unknown ")
	}
	if len(id) >= 8 {
		return logger(id[:8] + " ")
	}
	return logger(id + " ")
}

// 环境变量读取函数
func getEnvString(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if boolValue, err := strconv.ParseBool(value); err == nil {
			return boolValue
		}
	}
	return defaultValue
}
