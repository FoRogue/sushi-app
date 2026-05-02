package proxy

import (
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"

	"github.com/gin-gonic/gin"
)

// New создаёт reverse proxy к targetAddr.
// servicePrefix — часть пути, которую нужно убрать.
// Пример: /api/auth/register/customer → /api/register/customer
func New(targetAddr, servicePrefix string) gin.HandlerFunc {
	target, err := url.Parse(targetAddr)
	if err != nil {
		panic("gateway: invalid target URL: " + targetAddr)
	}

	p := &httputil.ReverseProxy{
		Director: func(req *http.Request) {
			req.URL.Scheme = target.Scheme
			req.URL.Host = target.Host
			req.Host = target.Host
			req.URL.Path = "/api" + strings.TrimPrefix(req.URL.Path, "/api/"+servicePrefix)
		},
	}

	return func(c *gin.Context) {
		p.ServeHTTP(c.Writer, c.Request)
	}
}
