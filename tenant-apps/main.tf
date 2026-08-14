locals {
  labels = {
    "app"                 = var.app_name
    "idp.demo/tenant"     = var.tenant
    "idp.demo/plane"      = "tenant-apps"
    "idp.demo/managed-by" = "tenant-dev"
  }

  probe_script = <<-PY
    import http.server
    import os
    import threading
    import time
    import urllib.error
    import urllib.request

    PORT = int(os.environ.get("HTTP_PORT", "8080"))
    INTERVAL = int(os.environ.get("PROBE_INTERVAL", "5"))
    APP = os.environ.get("APP_NAME", "app")
    ALLOW = [u.strip() for u in os.environ.get("TARGETS_ALLOW", "").split(",") if u.strip()]
    DENY = [u.strip() for u in os.environ.get("TARGETS_DENY", "").split(",") if u.strip()]

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"ok\n")

        def log_message(self, fmt, *args):
            return

    def serve():
        http.server.HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()

    threading.Thread(target=serve, daemon=True).start()
    print(f"{APP} listening on :{PORT} allow={ALLOW} deny={DENY}", flush=True)

    def probe(url, expect_allow):
        try:
            with urllib.request.urlopen(url, timeout=2) as resp:
                print(f"ALLOW ok {url} status={resp.status}", flush=True)
                if not expect_allow:
                    print(f"UNEXPECTED_ALLOW {url}", flush=True)
        except Exception as exc:
            if expect_allow:
                print(f"FAIL {url} err={type(exc).__name__}:{exc}", flush=True)
            else:
                print(f"DENY timeout/fail {url} err={type(exc).__name__}:{exc}", flush=True)

    while True:
        for url in ALLOW:
            probe(url, True)
        for url in DENY:
            probe(url, False)
        time.sleep(INTERVAL)
  PY
}

resource "kubernetes_config_map_v1" "probe" {
  metadata {
    name      = "${var.app_name}-probe"
    namespace = var.tenant
    labels    = local.labels
  }

  data = {
    "probe.py" = local.probe_script
  }
}

resource "kubernetes_deployment_v1" "app" {
  metadata {
    name      = var.app_name
    namespace = var.tenant
    labels    = local.labels
  }

  spec {
    replicas = var.replicas

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "0"
        max_unavailable = "1"
      }
    }

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = local.labels
        annotations = {
          "idp.demo/probe-script-hash" = sha256(local.probe_script)
        }
      }

      spec {
        container {
          name    = var.app_name
          image   = var.image
          command = ["python", "/app/probe.py"]

          port {
            container_port = var.http_port
            name           = "http"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          env {
            name  = "APP_NAME"
            value = var.app_name
          }
          env {
            name  = "HTTP_PORT"
            value = tostring(var.http_port)
          }
          env {
            name  = "PROBE_INTERVAL"
            value = tostring(var.probe_interval_seconds)
          }
          env {
            name  = "TARGETS_ALLOW"
            value = join(",", var.targets_allow)
          }
          env {
            name  = "TARGETS_DENY"
            value = join(",", var.targets_deny)
          }

          volume_mount {
            name       = "probe"
            mount_path = "/app"
            read_only  = true
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = var.http_port
            }
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = var.http_port
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }

        volume {
          name = "probe"
          config_map {
            name = kubernetes_config_map_v1.probe.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "app" {
  metadata {
    name      = var.app_name
    namespace = var.tenant
    labels    = local.labels
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      name        = "http"
      port        = var.http_port
      target_port = var.http_port
    }

    type = "ClusterIP"
  }
}
