# ═══════════════════════════════════════════════════════════════════
# CP2 — Containerization: multi-stage build, non-root user, healthcheck
# Build thử: docker build -t day12-agent:prod .
#            docker images day12-agent:prod     # xem dung lượng
# ═══════════════════════════════════════════════════════════════════

# ── Stage 1: builder — cài dependency, không lên image cuối cùng ────
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: runtime — chỉ mang theo Python + package đã cài sẵn ────
FROM python:3.11-slim AS runtime

WORKDIR /app

# Lấy package đã cài từ stage builder (không pip install lại, không mang
# theo build tool/cache của pip)
COPY --from=builder /install /usr/local

# Tạo user thường rồi copy source — container không được chạy bằng root
RUN useradd --create-home --shell /bin/bash appuser

COPY . .

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["python", "-c", "import os, urllib.request; urllib.request.urlopen('http://localhost:' + os.environ.get('PORT', '8000') + '/health')"]

# PORT đọc từ biến môi trường (cloud tự gán cổng khác nhau mỗi lần deploy).
# 'exec' để uvicorn thay thế shell làm tiến trình PID 1 và nhận SIGTERM
# trực tiếp — cần cho graceful shutdown ở CP4.
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
