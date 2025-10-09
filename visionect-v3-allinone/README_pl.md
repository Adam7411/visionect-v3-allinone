[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FAdam7411%2Fvisionect-v3-allinone)

<!-- README.md -->
<div align="right">
<a href="README.md">English</a> | <a href="README_pl.md">Polski</a>
</div>

# Visionect Server v3 (All‑in‑One) – Dodatek Home Assistant

Visionect Server v3 (oficjalny obraz) + PostgreSQL + Redis w jednym kontenerze dodatku Home Assistant.  
Przetestowano z tabletem Joan 6.

> WAŻNE: Dodatek owija oficjalny obraz `visionect/visionect-server-v3:7.6.5`. Użycie podlega oryginalnej licencji Visionect. Ten repozytorium zawiera tylko logikę integracyjną (baza danych, redis, skrypty startowe). 




## Instalacja

1. Dodaj URL repozytorium jako Custom Repository w Sklepie dodatków HA.

   (Wchodzimy w Ustawienia -> Dodatki -> Sklep z dodatkami -> menu z trzema kropeczkami u góry po prawej -> Repozytoria -> wklejemy https://github.com/Adam7411/visionect-v3-allinone w miejsce Dodaj -> +Dodaj)
2. Wybierz „Visionect Server v3 (All-in-One)” → Zainstaluj.
3. Uruchom dodatek.
4. Otwórz UI: `http://<adres_HA>:8081` uruchomi się server Visionect Software Suite

## 📲 Krok 5: Konfiguracja tabletu Visionect

1.  Pobierz i uruchom aplikację **Visionect Configurator** na swoim komputerze:
    *   **Windows:** [VisionectConfigurator.exe](https://files.visionect.com/VisionectConfigurator/VisionectConfigurator.exe) lub [joan-configurator-2.1.3-windows.exe](https://configurator.getjoan.com/download/flavor/joan/latest/windows_64) 
    *   **Windows: wersje 1.3.10-->** [VisionectConfigurator1.3.10.exe](https://files.visionect.com/VisionectConfigurator2.exe) lub [VC_1.exe](https://files.visionect.com/VC_1.exe) gdy wyświetlacz e-ink niełączy się z nową (Hardware Revision Second generation Visionect Sign 6) niekiedy trzeba skonfigurować przez [VC_1.exe] albo v1.3.10 cierpliwie pokombinuj.
    *   **Linux:** [VisionectConfigurator_linux.deb](https://files.visionect.com/VisionectConfigurator/VisionectConfigurator_linux.deb)
    *   **macOS (Apple Silicon):** [VisionectConfigurator_m1.dmg](https://files.visionect.com/VisionectConfigurator/VisionectConfigurator_m1.dmg)
    *   **macOS (Intel):** [VisionectConfigurator_intel.dmg](https://files.visionect.com/VisionectConfigurator/VisionectConfigurator_intel.dmg)
2.  Podłącz tablet do komputera za pomocą kabla USB.
3.  Po wykryciu tabletu przez aplikację:
    *   Wybierz swoją sieć Wi-Fi i wpisz hasło.
    *   Przejdź do zakładki **Advanced Connectivity**.
    *   Wprowadź dane swojego serwera:
        *   **Server IP**: Adres IP Home Assistanta (np. `192.168.1.100`).
        *   **Port**: `11113`
     
   Visionect Configurator v2.0
   ![image](https://github.com/user-attachments/assets/de30fd1e-9bd3-4f98-ab00-9a3b534f7332)

   Visionect Configurator v1.0
   <img width="754" height="501" alt="Bez tytułu" src="https://github.com/user-attachments/assets/5b99deac-d54d-405b-8aef-70653a56dbc9" />

_______________________________________________


4.  Kliknij przycisk, aby połączyć tablet z serwerem.
5.  Po chwili tablet powinien pojawić się w panelu **Visionect Software Suite** na liście urządzeń.
<img width="1836" height="729" alt="pppp" src="https://github.com/user-attachments/assets/1aaae475-87b1-4e0f-a94e-ddddb0ee9df9" />

---

## ✏️ Krok 6: Tworzenie dashboardu w Home Assistant 
_______________________________________________________________________________

Użyjemy dodatku **AppDaemon**.

1.  Zainstaluj dodatek **AppDaemon** w Home Assistant (jeśli jeszcze go nie masz).
2.  Przejdź do katalogu konfiguracyjnego AppDaemon, np. przez dodatek "Samba share" lub "File editor":  
    `\config\appdaemon\dashboards\` ( umnie to wygląda tak \\adres HA\addon_configs\a7c7b154_appdaemon\dashboards\ )
3.  Utwórz w tym katalogu nowy plik z rozszerzeniem `.dash`, np. `joanl.dash`.
4.  Możesz skorzystać z gotowych szablonów dashboardów z tego repozytorium:
    *   [joan1.dash](https://github.com/Adam7411/Joan-6-Visionect_Home-Assistant/blob/main/joan1.dash)
    *   [joan2.dash](https://github.com/Adam7411/Joan-6-Visionect_Home-Assistant/blob/main/joan2.dash)
5.  **Ważne:** Zmodyfikuj plik `joanl.dash lub joan2.dash`, podmieniając przykładowe encje na własne encje z Home Assistant. Szczegółową dokumentację tworzenia dashboardów znajdziesz na [oficjalnej stronie AppDaemon](https://appdaemon.readthedocs.io/en/latest/DASHBOARD_CREATION.html).
6.  Zrestartuj dodatek AppDaemon, aby załadować nową konfigurację.
7.  Sprawdź, czy Twój dashboard działa, otwierając w przeglądarce adres:  
    `http://<adres_ip_ha>:5050/joan1`  
    (zmień `joanl` na nazwę swojego pliku `.dash` jeśli nie chcesz używać przykładowych plików).
8.  Skopiuj ten adres URL.
9.  Wróć do panelu **Visionect Software Suite**, przejdź do ustawień swojego tabletu i w polu **Default URL** wklej skopiowany adres dashboardu. Zapisz zmiany.
    ![image](https://github.com/user-attachments/assets/00558b5d-ad93-44ab-b4f0-ae8e9b1be20f)
10. Po chwili na ekranie tabletu powinien pojawić się twój dashboard z AppDaemon. Dashboard można też ustawiać z poziomu Home Assistant przez dodatek 👉 [Visionect Joan](https://github.com/Adam7411/visionect_joan) 👈

### Dodatkowe porady
*   Dla każdego tabletu możesz utworzyć osobny plik `.dash` i przypisać mu unikalny adres URL.
*   W panelu Visionect warto również dostosować **częstotliwość odświeżania** (`Refresh rate`), aby zbalansować aktualność danych i zużycie baterii.
    ![image](https://github.com/user-attachments/assets/9f0c1741-76f3-496d-ad44-e316d29621f1)

---

## ⭐ Obowiazkowa integracja Visionect Joan dla Home Assistant (Odczyt stanu tabletu i wysyłanie zdjęc url i własnego tekstu)


Integracja do odczytu w Home Assistant informacji o stanie tabletu Joan (np. poziom naładowania baterii, status połączenia itp) 
Do wysyłania swojego adresu url tekstu i zdjęć z poziomu HA na Joan 6 np. ( https://www.wikipedia.org/ ) lub lokalne zdjęć ( przykład http://adresHA:8123/local/zdjecie_test.png ) 
(P.S plik zdjecie_test.png umieszczamy w katalogu: \192.168.xxx.xxx\config\www\) 


👉 [Visionect Joan](https://github.com/Adam7411/visionect_joan) 👈
👉 [Visionect Joan](https://github.com/Adam7411/visionect_joan) 👈

Pozwoli to na tworzenie automatyzacji n.p:

wysyłania powiadomienia o niskim stanie baterii Joan 6 albo wyświetlenie encji z poziomem baterii na Joan 6

wysyłanie zdjęć do różnych powiadomień poczym spowrotem powrót do dashboardu appdaemon itp.

wysyłanie zrzutu z kamery snapshot.jpg

wysyłanie powiadomień tekstowych z Home Assistant na Joan 6 itp
