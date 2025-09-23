[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FAdam7411%2Fvisionect-v3-allinone)

[Polska wersja dokumentacji (README_pl.md)](https://github.com/Adam7411/visionect-v3-allinone/blob/main/visionect-v3-allinone/README_pl.md)

# Visionect Server v3 (All‑in‑One) Home Assistant Add-on

All‑in‑one packaged Visionect Server v3 stack (Visionect upstream image + embedded PostgreSQL + Redis) for Home Assistant Supervisor.  
Tested with a Joan 6 e‑paper device.

> IMPORTANT: This add-on wraps the official `visionect/visionect-server-v3:7.6.5` Docker image. Usage is subject to Visionect’s original license/terms. This repository only adds orchestration glue (database + redis + HA integration). 



## Installation

1. Add this custom repository URL to Home Assistant Add-on Store.
2. Locate “Visionect Server v3 (All-in-One)” in the store.
3. Click Install.
4. Start the add-on.
5. Open Web UI (or navigate to `http://<HA_HOST>:8081`).
## 📲 Step 5: Configure the Tablet

1. Download Visionect Configurator:

   * Windows: [VisionectConfigurator.exe](https://files.visionect.com/VisionectConfigurator/VisionectConfigurator.exe)
   * Linux: [VisionectConfigurator\_linux.deb](https://files.visionect.com/VisionectConfigurator/VisionectConfigurator_linux.deb)
   * macOS: [Intel](https://files.visionect.com/VisionectConfigurator/VisionectConfigurator_intel.dmg) | [Apple Silicon](https://files.visionect.com/VisionectConfigurator/VisionectConfigurator_m1.dmg)
   * Older version Windows:  [1.3.10](https://files.visionect.com/VisionectConfigurator2.exe) or [VC_1.exe](https://files.visionect.com/VC_1.exe)

2. Connect the tablet to USB.

3. Select Wi-Fi, enter password.

4. Go to **Advanced Connectivity**:

   * Server Home Assistant IP: e.g., `192.168.1.100` 
   * Port: `11113`
     
    Visionect Configurator v2.0
   ![image](https://github.com/user-attachments/assets/de30fd1e-9bd3-4f98-ab00-9a3b534f7332)

    Visionect Configurator v1.0
   <img width="754" height="501" alt="Bez tytułu" src="https://github.com/user-attachments/assets/5b99deac-d54d-405b-8aef-70653a56dbc9" />

6. Click connect. The tablet should appear in the Visionect server panel.
<img width="1836" height="729" alt="pppp" src="https://github.com/user-attachments/assets/fa23b582-e5bd-4538-ab95-8d18f6948d04" />
---

## ✏️ Step 6: Create a Dashboard for Home Assistant

> You can also use [Puppeteer version](https://github.com/Adam7411/Joan-6-Puppeteer/blob/main/README.md) if you don't want to use AppDaemon.

1. Install **AppDaemon** in Home Assistant.
2. Go to: `\HA_IP\config\appdaemon\dashboards\` \addon_configs\a7c7b154_appdaemon\dashboards\ )
3. Create a file, e.g., `joan1.dash`
4. Example files:

   * [joan1.dash](https://github.com/Adam7411/Joan-6-Visionect_Home-Assistant/blob/main/joan1.dash)
   * [joan2.dash](https://github.com/Adam7411/Joan-6-Visionect_Home-Assistant/blob/main/joan2.dash)
5. Edit and insert your own Home Assistant entities.
6. Restart AppDaemon.
7. Test: `http://<HA_IP>:5050/joan1`
8. Copy URL, paste into **Default URL** in Visionect dashboard settings.
9. Adjust **Refresh Rate** if necessary (e.g., 2 seconds initially).
---

Integration with Home Assistant (Tablet status reading and URL sending)
Integration for reading information about the status of the Joan tablet in Home Assistant (e.g. battery level, connection status, etc.), as well as for sending your own URL ( e.g. https://www.wikipedia.org/ ) or local images ( example: http://HAaddress:8123/local/test_image.png
P.S. The file test_image.png should be placed in the folder: \\192.168.xxx.xxx\config\www\

👉 [Visionect Joan](https://github.com/Adam7411/visionect_joan) 👈
👉 [Visionect Joan](https://github.com/Adam7411/visionect_joan) 👈


This allows for creating automations, such as sending low battery notifications, displaying an entity with battery level on the tablet, or sending images for different notifications, and then returning to the AppDaemon dashboard, etc.

<img width="510" height="739" alt="3" src="https://github.com/user-attachments/assets/8f8c673d-8447-42ec-9d13-0bd4e9683437" /> <img width="948" height="791" alt="2" src="https://github.com/user-attachments/assets/4a3c054a-e239-49c1-ab9d-037584cd7989" /> <img width="607" height="893" alt="1" src="https://github.com/user-attachments/assets/1321cfe8-905d-44ef-b1b9-29d999559a04" /> <img width="770" height="641" alt="4" src="https://github.com/user-attachments/assets/31e9bca1-d7c6-4245-b32f-4c909251bf2c" />


