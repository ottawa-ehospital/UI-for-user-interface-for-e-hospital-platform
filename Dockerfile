FROM ubuntu:22.04 as builder
RUN apt-get update && apt-get install -y git curl unzip xz-utils
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:${PATH}"
RUN flutter config --no-analytics && flutter precache
WORKDIR /app
COPY . .
RUN flutter pub get && flutter build web --release

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]