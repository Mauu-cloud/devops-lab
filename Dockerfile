# ---- Etapa 1: instalar dependencias (multi-stage = imagen final más chica) ----
FROM python:3.12-slim AS builder
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- Etapa 2: imagen final ----
FROM python:3.12-slim
# Usuario sin privilegios: nunca correr contenedores como root
RUN useradd --create-home --uid 10001 appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app/main.py .
USER 10001
EXPOSE 8080
ENV APP_VERSION=dev
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--worker-tmp-dir", "/tmp", "main:app"]
