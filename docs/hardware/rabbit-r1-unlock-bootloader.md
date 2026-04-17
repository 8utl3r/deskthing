# Rabbit R1: Unlock Bootloader Guide

Step-by-step guide from [rabbit.tech/support/article/unlock-bootloader-rabbit-r1](https://www.rabbit.tech/support/article/unlock-bootloader-rabbit-r1).  
**Warning:** Developer mode and bootloader unlock **permanently void the warranty**.

---

## ✓ Already have developer mode — unlock now

1. **On the R1 (powered on, online, rabbithole logged in):**  
   **Settings → Developer → Device modification → Unlock**

2. **On your computer:** Open [rabbit-hmi-oss.github.io/flashing](https://rabbit-hmi-oss.github.io/flashing/).  
   Windows: install [MediaTek USB driver](https://github.com/rabbit-hmi-oss/flashing#prerequisites) first.

3. **Enter fastboot:**  
   - Power off R1, disconnect USB  
   - In the Flash Tool, click **Enter Fastboot Mode**  
   - Connect R1 via USB  
   - When the device picker appears, select **MT65xx Preloader** (e.g. MT6570) within ~1.5 seconds  
   - R1 screen will show **FASTBOOT**

4. **Unlock:** In the Flash Tool, select the device in fastboot and run the unlock (or follow the Tool’s on‑screen steps).  
   Community details: [XDA tutorial](https://xdaforums.com/t/how-to-unlock-rabbit-r1-bootloader-tutorial.4676024/).

---

## Part 1: Request Developer Mode (required first)

You must have Rabbit support enable developer mode before the device will allow unlocking.

1. **Get your R1 IMEI**  
   On the device: **Settings → About**. Note the IMEI.

2. **Submit the request**  
   - Go to [rabbit.tech/contact-us](https://www.rabbit.tech/contact-us)  
   - Name and email  
   - Reason: **Developer mode**  
   - Provide:
     - IMEI of your R1  
     - Email used for your rabbithole account  
   - **Required message** (copy exactly):  
     _I acknowledge that the warranty on my rabbit r1 is permanently void once it is put in developer mode._  
   - Submit

3. **Wait**  
   Rabbit support will review and enable developer mode. There is no published SLA.

---

## Part 2: Unlock the Bootloader (after developer mode is enabled)

1. **Prep the device**
   - R1 powered on  
   - Connected to the internet  
   - Logged into your rabbithole account

2. **Unlock in settings**
   - Open **Settings**  
   - In the **Developer** section, find **Device modification**  
   - Tap **Unlock**

3. **Put R1 in fastboot**
   - Use the [Rabbit R1 Flash Tool](https://rabbit-hmi-oss.github.io/flashing/) to enter fastboot.  
   - On Windows: install the [MediaTek USB driver](https://github.com/rabbit-hmi-oss/flashing#prerequisites) first.

4. **Unlock in fastboot**
   - Once the device is in fastboot, complete the unlock using the Flash Tool or your preferred fastboot workflow.

**Note:** Rabbit does not provide support for unlocking the bootloader or flashing. For community help, use the [developers & modding section](https://community.rabbit.tech/) on the Rabbit forum.

---

## Part 3: Flashing and Reverting

- **Flash custom/third‑party images:**  
  Rabbit does not recommend or support third‑party ROMs. Use the [Rabbit community developers & modding section](https://community.rabbit.tech/) for community guidance.

- **Revert to stock rabbitOS:**  
  Use the [Rabbit R1 Flash Tool](https://rabbit-hmi-oss.github.io/flashing/) and follow its instructions to flash back to stock.  
  Firmware: [rabbit-hmi-oss/firmware](https://github.com/rabbit-hmi-oss/firmware) releases.

---

## Quick reference

| Resource | URL |
|----------|-----|
| Contact (developer mode request) | [rabbit.tech/contact-us](https://www.rabbit.tech/contact-us) |
| R1 Flash Tool | [rabbit-hmi-oss.github.io/flashing](https://rabbit-hmi-oss.github.io/flashing/) |
| rabbitOS firmware | [github.com/rabbit-hmi-oss/firmware](https://github.com/rabbit-hmi-oss/firmware) |
| Kernel source (GPL) | [rabbit-hmi-oss](https://github.com/rabbit-hmi-oss) on GitHub |
| Community / modding | [community.rabbit.tech](https://community.rabbit.tech/) |
