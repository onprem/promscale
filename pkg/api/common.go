// This file and its contents are licensed under the Apache License 2.0.
// Please see the included NOTICE for copyright information and
// LICENSE for a copy of the license.

package api

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"math"
	"net/http"
	"strconv"
	"time"

	"github.com/grafana/regexp"

	"github.com/prometheus/common/model"
	"github.com/prometheus/prometheus/promql/parser"
	"github.com/prometheus/prometheus/storage"
	"github.com/prometheus/prometheus/util/httputil"
	"github.com/timescale/promscale/pkg/ha"
	"github.com/timescale/promscale/pkg/log"
	pgmodel "github.com/timescale/promscale/pkg/pgmodel/model"
	"github.com/timescale/promscale/pkg/promql"
	"github.com/timescale/promscale/pkg/rules"
	"github.com/timescale/promscale/pkg/tenancy"
)

var (
	minTimeFormatted = pgmodel.MinTime.Format(time.RFC3339Nano)
	maxTimeFormatted = pgmodel.MaxTime.Format(time.RFC3339Nano)
)

type Config struct {
	AllowedOrigin    *regexp.Regexp
	ReadOnly         bool
	HighAvailability *ha.Config
	AdminAPIEnabled  bool
	TelemetryPath    string

	MultiTenancy tenancy.Authorizer
	Rules        *rules.Manager
}

func ParseFlags(fs *flag.FlagSet, cfg *Config) *Config {
	cfg.HighAvailability = ha.ParseFlags(fs)

	fs.BoolVar(&cfg.ReadOnly, "db.read-only", false, "Read-only mode for the connector. Operations related to writing or updating the database are disallowed. It is used when pointing the connector to a TimescaleDB read replica.")
	fs.BoolVar(&cfg.AdminAPIEnabled, "web.enable-admin-api", false, "Allow operations via API that are for advanced users. Currently, these operations are limited to deletion of series.")
	fs.StringVar(&cfg.TelemetryPath, "web.telemetry-path", "/metrics", "Web endpoint for exposing Promscale's Prometheus metrics.")

	return cfg
}

func Validate(cfg *Config) error {
	return cfg.HighAvailability.Validate()
}

func corsWrapper(conf *Config, f http.HandlerFunc) http.HandlerFunc {
	if conf.AllowedOrigin == nil {
		return f
	}
	return func(w http.ResponseWriter, r *http.Request) {
		httputil.SetCORS(w, conf.AllowedOrigin, r)
		f(w, r)
	}
}

func setResponseHeaders(w http.ResponseWriter, samples *promql.Result, isExemplar bool, warnings storage.Warnings) {
	w.Header().Set("Content-Type", "application/json")
	if len(warnings) > 0 {
		w.Header().Set("Cache-Control", "no-store")
	}
	if isExemplar {
		// Exemplar response headers do not return StatusNoContent, if data is nil.
		w.WriteHeader(http.StatusOK)
		return
	}
	if samples != nil && samples.Value != nil {
		w.WriteHeader(http.StatusOK)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func respondQuery(w http.ResponseWriter, res *promql.Result, warnings storage.Warnings) {
	setResponseHeaders(w, res, false, warnings)
	switch resVal := res.Value.(type) {
	case promql.Vector:
		warnings := make([]string, 0, len(res.Warnings))
		for _, warn := range res.Warnings {
			warnings = append(warnings, warn.Error())
		}
		_ = marshalVectorResponse(w, resVal, warnings)
	case promql.Matrix:
		warnings := make([]string, 0, len(res.Warnings))
		for _, warn := range res.Warnings {
			warnings = append(warnings, warn.Error())
		}
		_ = marshalMatrixResponse(w, resVal, warnings)
	default:
		resp := &response{
			Status: "success",
			Data: &queryData{
				ResultType: res.Value.Type(),
				Result:     res.Value,
			},
		}
		for _, warn := range res.Warnings {
			resp.Warnings = append(resp.Warnings, warn.Error())
		}
		_ = json.NewEncoder(w).Encode(resp)
	}
}

func respondExemplar(w http.ResponseWriter, data []pgmodel.ExemplarQueryResult) {
	setResponseHeaders(w, nil, true, nil)
	_ = marshalExemplarResponse(w, data)
}

func respond(w http.ResponseWriter, status int, message interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)

	// The ideal response to code 200 should be "success" as per Prometheus.
	// Hence, we do not do http.StatusText(200) as that will return "OK"
	// which does not align with Prometheus.
	statusText := "success"
	if status != http.StatusOK {
		statusText = http.StatusText(status)
	}

	_ = json.NewEncoder(w).Encode(&response{
		Status: statusText,
		Data:   message,
	})
}

func respondError(w http.ResponseWriter, status int, err error, errType string) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	b, err := json.Marshal(&errResponse{
		Status:    "error",
		ErrorType: errType,
		Error:     err.Error(),
	})
	if err != nil {
		log.Error("msg", "error marshalling json error", "err", err)
	}
	if n, err := w.Write(b); err != nil {
		log.Error("msg", "error writing response", "bytesWritten", n, "err", err)
	}
}

func respondErrorWithMessage(w http.ResponseWriter, status int, err error, errType string, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	b, err := json.Marshal(&errResponse{
		Status:    "error",
		ErrorType: errType,
		Error:     err.Error(),
		Message:   message,
	})
	if err != nil {
		log.Error("msg", "error marshalling json error", "err", err)
	}
	if n, err := w.Write(b); err != nil {
		log.Error("msg", "error writing response", "bytesWritten", n, "err", err)
	}
}

type errResponse struct {
	Status    string `json:"status"`
	ErrorType string `json:"errorType"`
	Error     string `json:"error"`
	Message   string `json:"message,omitempty"`
}

type response struct {
	Status   string      `json:"status"`
	Data     interface{} `json:"data,omitempty"`
	Warnings []string    `json:"warnings,omitempty"`
}

type queryData struct {
	ResultType parser.ValueType `json:"resultType"`
	Result     parser.Value     `json:"result"`
}

func marshalMatrixResponse(writer io.Writer, data promql.Matrix, warnings []string) error {
	out := &errorWrapper{writer: writer}
	marshalCommonHeader(out)
	marshalMatrixData(out, data)
	marshalCommonFooter(out, warnings, true)
	return out.err
}

func parseTimeParam(r *http.Request, paramName string, defaultValue time.Time) (time.Time, error) {
	val := r.FormValue(paramName)
	if val == "" {
		return defaultValue, nil
	}
	result, err := parseTime(val)
	if err != nil {
		return time.Time{}, fmt.Errorf("Invalid time value for '%s': %w", paramName, err)
	}
	return result, nil
}

func parseTime(s string) (time.Time, error) {
	if t, err := strconv.ParseFloat(s, 64); err == nil {
		s, ns := math.Modf(t)
		ns = math.Round(ns*1000) / 1000
		return time.Unix(int64(s), int64(ns*float64(time.Second))).UTC(), nil
	}
	if t, err := time.Parse(time.RFC3339Nano, s); err == nil {
		return t, nil
	}

	// Stdlib's time parser can only handle 4 digit years. As a workaround until
	// that is fixed we want to at least support our own boundary times.
	// Context: https://github.com/prometheus/client_golang/issues/614
	// Upstream issue: https://github.com/golang/go/issues/20555
	switch s {
	case minTimeFormatted:
		return pgmodel.MinTime, nil
	case maxTimeFormatted:
		return pgmodel.MaxTime, nil
	}
	return time.Time{}, fmt.Errorf("cannot parse %q to a valid timestamp", s)
}

func parseDuration(s string) (time.Duration, error) {
	if d, err := strconv.ParseFloat(s, 64); err == nil {
		ts := d * float64(time.Second)
		if ts > float64(math.MaxInt64) || ts < float64(math.MinInt64) {
			return 0, fmt.Errorf("cannot parse %q to a valid duration. It overflows int64", s)
		}
		return time.Duration(ts), nil
	}
	if d, err := model.ParseDuration(s); err == nil {
		return time.Duration(d), nil
	}
	return 0, fmt.Errorf("cannot parse %q to a valid duration", s)
}
