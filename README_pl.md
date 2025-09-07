[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FAdam7411%2Fvisionect-v3-allinone)

<!-- README_PL.md -->
<div align="right">
<a href="README.md">English</a> | <a href="README_pl.md">Polski</a>
</div>

# Visionect Server v3 (All‑in‑One) – Dodatek Home Assistant

Visionect Server v3 (oficjalny obraz) + PostgreSQL + Redis w jednym kontenerze dodatku Home Assistant.  
Przetestowano z tabletem Joan 6.

> WAŻNE: Dodatek owija oficjalny obraz `visionect/visionect-server-v3:7.6.5`. Użycie podlega oryginalnej licencji Visionect. Ten repozytorium zawiera tylko logikę integracyjną (baza danych, redis, skrypty startowe). Upewnij się, że masz prawo używać oprogramowania Visionect.

## Instalacja

1. Dodaj URL repozytorium jako Custom Repository w Sklepie dodatków HA.
2. Wybierz „Visionect Server v3 (All-in-One)” → Zainstaluj.
3. Uruchom dodatek.
4. Otwórz UI: `http://<adres_HA>:8081`.

   
## Spis treści

- [Funkcje](#funkcje)
- [Architektura](#architektura)
- [Obsługiwane platformy](#obsługiwane-platformy)
- [Porty](#porty)
- [Trwałość danych](#trwałość-danych)
- [Zawarte komponenty](#zawarte-komponenty)
- [Instalacja](#instalacja)
- [Konfiguracja (schema options.json)](#konfiguracja-schema-optionsjson)
- [Healthcheck](#healthcheck)
- [Logi](#logi)
- [Aktualizacje](#aktualizacje)
- [Rozwiązywanie problemów](#rozwiązywanie-problemów)
- [Uwagi bezpieczeństwa](#uwagi-bezpieczeństwa)
- [Mapa rozwoju](#mapa-rozwoju)
- [Licencja / Zastrzeżenia](#licencja--zastrzeżenia)
- [Zmiany](#zmiany)
- [Sprzęt testowy](#sprzęt-testowy)
- [Wkład / Kontrybucje](#wkład--kontrybucje)
- [Wsparcie](#wsparcie)

---

## Funkcje

- Zintegrowany serwer Visionect + PostgreSQL + Redis
- Automatyczna inicjalizacja użytkownika i bazy
- Opcjonalne autodetekcja IP hosta (gdy `visionect_server_address=localhost`)
- Lekka pętla healthcheck (curl)
- Trwałe logi (`/data/logs`)
- Obsługa amd64, aarch64, armv7
- Przetestowano z Joan 6

---

## Architektura

```
HA Supervisor -> Kontener dodatku:
  - redis-server
  - postgres (127.0.0.1)
  - supervisord (admin / engine / gateway / networkmanager)
  - bootstrap (run.sh)
Porty wystawione: 8081 (UI), 11113 (urządzenia)
```

---

## Obsługiwane platformy

| Architektura | Status | Uwagi |
|--------------|--------|-------|
| amd64        | ✅     | Testowane |
| aarch64      | ✅     | Raspberry Pi 4/5 |
| armv7        | ✅     | Raspberry Pi 3 (wolniejsze) |

---

## Porty

| Cel | Port kontener | Port hosta | Opis |
|-----|---------------|-----------|------|
| UI Visionect | 8081 | 8081/tcp | Interfejs zarządzania |
| Urządzenia / Koala | 11113 | 11113/tcp | Komunikacja z tabletami |

---

## Trwałość danych

| Ścieżka | Opis |
|---------|------|
| /data/pgdata | Dane PostgreSQL |
| /data/redis | Katalog redis (bez trwałego zapisu domyślnie) |
| /data/logs | Logi Visionect i dodatku |
| /data/options.json | Konfiguracja użytkownika |

Redis domyślnie bez RDB/AOF – szybki start i mniejsze zużycie nośnika.

---

## Zawarte komponenty

| Komponent | Źródło |
|-----------|--------|
| Visionect Server v3 | `visionect/visionect-server-v3:7.6.5` |
| PostgreSQL 14 | Pakiety Ubuntu |
| Redis 6 | Pakiety Ubuntu |
| Supervisord | Obraz Visionect |
| Healthcheck | Skrypt bash |


---

## Konfiguracja (schema options.json)

| Klucz | Typ | Domyślne | Opis |
|-------|-----|----------|------|
| postgres_user | string | visionect | Nazwa użytkownika |
| postgres_password | string | visionect | ZMIEŃ! |
| postgres_db | string | koala | Nazwa bazy |
| visionect_server_address | string | localhost | Adres zewnętrzny dla urządzeń |
| timezone | string/null | auto | Strefa czasowa |
| bind_address | string | 0.0.0.0 | Rezerwowe (akt. nieużywane) |
| healthcheck_enable | bool | true | Włącza pętlę sprawdzającą |
| healthcheck_url | string | http://127.0.0.1:8081 | URL sprawdzany |
| healthcheck_interval | int | 30 | Sekundy między testami |
| healthcheck_max_failures | int | 5 | Ile niepowodzeń przed restartem |

Przykład:
```json
{
  "postgres_user": "visionect",
  "postgres_password": "MojeSilneHaslo123",
  "postgres_db": "koala",
  "visionect_server_address": "192.168.1.50",
  "timezone": "Europe/Warsaw",
  "healthcheck_enable": true
}
```

---

## Healthcheck

Pętla `curl` monitoruje UI. Po `healthcheck_max_failures` nieudanych próbach kontener wychodzi → Supervisor restartuje.

---

## Logi

- Lokalizacja trwała: `/data/logs`
- Podgląd w UI dodatku (stdout)
- Pliki: `admin.log`, `engine.log`, `gateway.log`, `networkmanager.log`

---

## Aktualizacje

1. Kopia zapasowa HA
2. Aktualizacja dodatku w UI
3. Dane PostgreSQL zachowane
4. Przy zmianach głównej wersji Visionect – test na środowisku testowym

---

## Rozwiązywanie problemów

| Objaw | Przyczyna | Rozwiązanie |
|-------|-----------|-------------|
| Restartuje się | Healthcheck pada | Sprawdź UI / port 8081 |
| Brak UI | Port zajęty | Zmień mapowanie portu |
| Urządzenie nie łączy | Zły adres serwera | Ustaw `visionect_server_address` na IP LAN |
| Puste logi | Symlink nie powstał | Usuń `/var/log/vss`, restart |

Diagnostyka:
```
ss -ltnp
tail -n 100 /data/logs/*.log
ps -ef | grep -i visionect
```

---

## Uwagi bezpieczeństwa

- Zmień hasło `postgres_password`
- Rozważ reverse proxy + TLS
- Nie wystawiaj portów publicznie bez ochrony
- Wbudowana baza = wygoda, nie zawsze idealna dla produkcji

---

## Mapa rozwoju

- Obsługa zewnętrznego PostgreSQL
- Włączenie persistent Redis (opcjonalnie)
- Ingress
- Auto-backup
- Panel statusu urządzeń

---

## Licencja / Zastrzeżenia

- Visionect Server: licencja Visionect (zewnętrzna).
- Ten wrapper: (np.) MIT – dostosuj według potrzeb.
- Brak gwarancji. Używasz na własne ryzyko.

---

## Zmiany

Patrz historia Git (lub dodany plik `CHANGELOG.md` w przyszłości).

---

## Sprzęt testowy

- Joan 6 – rejestracja i interfejs działają prawidłowo.

---

## Wkład / Kontrybucje

Chętnie przyjmowane:
1. Fork
2. Branch
3. Commit
4. Pull Request (z opisem zmian & testami)

---

## Wsparcie

Zgłoś Issue w repozytorium:
- Wersja dodatku
- Fragmenty logów
- Kroki odtworzenia


