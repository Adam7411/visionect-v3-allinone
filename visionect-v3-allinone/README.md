# Visionect Server v3 (All‑in‑One) — Home Assistant Add-on 

Ten dodatek uruchamia Visionect Server v3, PostgreSQL i Redis w jednym kontenerze (armv7/aarch64).

## Funkcje
- Visionect Server v3 (bazowy obraz `visionect/visionect-server-v3:7.6.5-arm`)
- PostgreSQL (dane w `/data/pgdata`, automatyczna inicjalizacja użytkownika i bazy z opcji)
- Redis (lokalny)
- Porty: 8081 (UI), 11113 (urządzenia)
- s6-overlay (init: true), watchdog do UI

## Instalacja
1. Skopiuj katalog `visionect-v3-allinone/` do repo dodatków i dodaj repo jako Custom repository w Home Assistant.
2. Zainstaluj dodatek „Visionect Server v3 (All-in-One)”.
3. Ustaw opcje (user, password, db i VISIONECT_SERVER_ADDRESS) jeśli chcesz inne niż domyślne.
4. Uruchom dodatek i otwórz web UI: `http://<HA_IP>:8081`.

## Uwagi dot. obrazu bazowego
- Dockerfile używa `FROM ${VSS_IMAGE}` (patrz `build.yaml`).
- Jeśli obraz Visionect dla aarch64 ma inny tag (np. `...-arm64`), zaktualizuj odpowiednio `build.yaml`.
- Jeśli podczas budowy pojawi się błąd „apt-get not found”, obraz Visionect jest bazą Alpine. Wtedy zamień fragment instalacji pakietów na:
  ```sh
  apk add --no-cache ca-certificates curl xz jq postgresql redis redis-cli
  ```
  oraz upewnij się, że ścieżki binarek postgres/redis są prawidłowe.

## Uprawnienia i bezpieczeństwo
- Wymagane: `SYS_ADMIN`, `MKNOD`, `apparmor: false`, `/dev/fuse` — to wymagania Visionect.
- Postgres nasłuchuje tylko na `127.0.0.1`, brak ekspozycji na zewnątrz.
- Dane Postgresa i Redisa są w `/data`.

## Troubleshooting
- Jeśli UI nie odpowiada, sprawdź logi dodatku; skrypt `vss/run` wypisze którą ścieżkę Visionect próbuje uruchomić. Wejdź do kontenera:
  ```
  docker exec -it addon_<slug> /bin/bash
  ls -l /
  ```
  i znajdź właściwy plik startowy. Podmień listę ścieżek w `etc/services.d/vss/run`.
