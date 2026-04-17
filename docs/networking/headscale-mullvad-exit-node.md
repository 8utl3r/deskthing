# Headscale + Mullvad Exit Node — Proxy Tailnet Internet via Mullvad

Use a **dedicated Linux machine** as a Headscale **exit node** that sends all exit traffic through **Mullvad VPN**. Any device on your tailnet (Tailscale app → Headscale) can then choose “Use exit node” and get internet via Mullvad, while your UDM Pro continues to provide **subnet routes** so LAN devices are reachable over the tailnet.

## Architecture

```
[Phone/Laptop/Mac]  ←→  Tailscale/Headscale mesh  ←→  [Exit node host]
                                                              │
                                                              ▼
                                                        [Mullvad VPN]
                                                              │
                                                              ▼
                                                        [Internet]
```

- **UDM Pro (subnet router):** Advertises `192.168.0.0/24` (or your LAN). Devices on the tailnet can reach LAN IPs. No change needed for this.
- **Exit node host:** New machine running Tailscale (advertise exit) + Mullvad WireGuard. Traffic from tailnet clients that “use exit node” goes: device → Tailscale → exit node → Mullvad → internet.
- **Headscale:** Approve the exit node’s routes (`0.0.0.0/0`, `::/0`) once the node is registered.

## What you need

- **Headscale** already running (e.g. on TrueNAS at `192.168.0.158`).
- **Mullvad** subscription and a **WireGuard** config (key + server). Get config at [mullvad.net](https://mullvad.net) → Account → WireGuard.
- **A Linux machine** for the exit node (Raspberry Pi, NUC, or VM with two interfaces or known gateway). It must:
  - Be on the same network as Headscale (or reachable from it) so the Tailscale client can talk to Headscale.
  - Have a stable LAN IP (or DHCP reservation).

This guide does **not** run the exit node on the UDM Pro (UniFi OS makes Mullvad + custom routing difficult) or inside TrueNAS (different OS model).

---

## Phase 1: Exit node host — Tailscale + advertise exit

On the **exit node machine** (Linux):

1. **Install Tailscale** (official packages for your distro).
2. **Create a Headscale user and pre-auth key** (from your Mac or wherever you run Headscale CLI):

   ```bash
   headscale users create exitnode   # or reuse existing user
   headscale preauthkeys create --user exitnode --reusable --expiration 720h
   ```

3. **Bring Tailscale up** pointing at Headscale and advertise exit (replace URL and key):

   ```bash
   sudo tailscale up \
     --login-server=http://192.168.0.158:30210 \
     --advertise-exit-node \
     --auth-key=preauthkey:YOUR_KEY \
     --accept-routes
   ```

4. **Enable IP forwarding** (required for exit node):

   ```bash
   # Persist across reboots (Linux)
   echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
   echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
   sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
   ```

5. **Confirm the node and routes on Headscale:**

   ```bash
   headscale nodes list
   headscale nodes list-routes
   ```

   You should see the new node and routes like `0.0.0.0/0` and `::/0` (advertised, not yet enabled).

---

## Phase 2: Exit node host — Mullvad WireGuard + routing

The exit node must send **all non-tailnet, non-LAN traffic** out through Mullvad. So:

- **Default route** → Mullvad WireGuard interface (`wg0`).
- **Tailscale ranges** → stay on `tailscale0` (Tailscale handles these).
- **Your LAN and Headscale server** → via normal gateway (so the node can reach Headscale and local hosts).

### 2.1 Install and bring up Mullvad WireGuard

- Install `wireguard-tools` (and optionally `wg-quick`).
- Add a Mullvad WireGuard config to `/etc/wireguard/mullvad.conf` (or `wg0.conf`). Get the config from Mullvad (Account → WireGuard → Generate key / Download config).
- Bring the interface up:

  ```bash
  sudo wg-quick up mullvad
  ```

  Do **not** make this the only default route yet if you do it by hand; the next step will set a **policy** so only traffic we want exits via Mullvad.

### 2.2 Routing and NAT (conceptual)

- **Default route:** Prefer Mullvad for general internet. Typical approach:
  - Bring up `wg0` with Mullvad’s `AllowedIPs = 0.0.0.0/0, ::/0` so the WireGuard config adds routes for everything, **or**
  - Add a default route via `wg0` and use **policy routing** so that traffic from `tailscale0` uses this default, while traffic from the host’s LAN interface uses the LAN gateway (for Headscale and LAN access).

- **Tailscale:** Tailscale’s daemon expects to receive traffic for `100.64.0.0/10` and `fd7a:115c:a1e0::/48` on `tailscale0`. Don’t send those to Mullvad; they’re handled by Tailscale.

- **LAN and Headscale:** Ensure the exit node can reach:
  - Your LAN (e.g. `192.168.0.0/24`) and
  - The Headscale server (e.g. `192.168.0.158`)
  via the normal gateway (not via `wg0`). So either:
  - Keep a higher-metric default via LAN and add a lower-metric default via `wg0`, and add explicit routes for LAN and Headscale via LAN gateway, or
  - Use policy routing: from `tailscale0` → use table that has default via `wg0`; from LAN interface → use table that has default via LAN gateway.

- **NAT:** Traffic coming **from** `tailscale0` and going **out** `wg0` must be NATed so Mullvad sees one source. Example (adjust interface names):

  ```bash
  sudo iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
  ```

  (On some distros you use `nft` instead; same idea: masquerade outbound via `wg0`.)

A minimal **single-interface** setup (exit node has one LAN interface and gets default from DHCP, then overrides with Mullvad):

1. Bring up Mullvad `wg0` so it has `AllowedIPs = 0.0.0.0/0, ::/0`. That will add a default route via `wg0`.
2. Add **more specific** routes **before** or **with higher priority** than that default:
   - Your LAN: e.g. `192.168.0.0/24 via <LAN_GW> dev eth0`
   - Headscale server: e.g. `192.168.0.158/32 via <LAN_GW> dev eth0`
   So the exit node reaches Headscale and LAN via LAN; everything else goes via `wg0`.
3. Tailscale traffic is process-local (tailscaled); traffic that **exits** the node to the internet (from tailscale0) will use the default route (wg0) if you’ve set the above. Enable NAT as above.

If your Mullvad config already pushes `0.0.0.0/0` via `wg0`, you only need to add the more-specific routes for LAN and Headscale so they don’t go over Mullvad.

### 2.3 Example: static routes (no Nix)

Assume:

- Exit node LAN IP: `192.168.0.50`, gateway `192.168.0.1`, interface `eth0`.
- Headscale at `192.168.0.158`.
- Mullvad interface: `wg0`.

After `wg-quick up mullvad`, add routes so LAN and Headscale stay on LAN:

```bash
# Ensure LAN and Headscale don’t go over Mullvad
sudo ip route add 192.168.0.0/24 via 192.168.0.1 dev eth0
sudo ip route add 192.168.0.158/32 via 192.168.0.1 dev eth0
```

NAT (once per boot or via iptables-persistent / firewalld):

```bash
sudo iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
```

Make these persistent using your distro’s mechanism (e.g. a small script in `/etc/network/if-up.d/` or systemd unit that runs after `wg-quick@mullvad` and Tailscale).

**Optional script:** In this repo, `scripts/headscale-exit-node-mullvad-routes.sh` adds the LAN/Headscale routes and NAT. Run it on the exit node after Mullvad is up (e.g. from a systemd unit or `wg-quick` post-up). Customize via env: `LAN_GW`, `LAN_DEV`, `LAN_CIDR`, `HEADSCALE_IP`, `MULLVAD_IF`.

---

## Phase 3: Headscale — Enable exit node routes

From your Mac (or wherever you run the Headscale CLI):

```bash
# List nodes and routes
headscale nodes list
headscale nodes list-routes
```

Find the **node ID** of the exit node and the advertised routes `0.0.0.0/0` (and optionally `::/0`). Approve the exit routes:

```bash
headscale nodes approve-routes --identifier <NODE_ID> --routes 0.0.0.0/0
```

Headscale typically enables the IPv6 exit route automatically when you approve `0.0.0.0/0`. Confirm:

```bash
headscale nodes list-routes
```

The exit node’s `0.0.0.0/0` and `::/0` should show as enabled/primary.

---

## Phase 4: Clients — Use the exit node

On any device that uses the Tailscale app and is connected to your Headscale tailnet:

- **macOS/Windows/Linux:** Tailscale menu → “Use exit node” → choose the hostname of your exit node.
- **Mobile:** Tailscale app → … → “Use exit node” → select the exit node.

That device’s internet traffic will then flow: device → Tailscale → exit node → Mullvad → internet. Your **router (UDM Pro)** is unchanged; it still provides subnet routes so the same devices can reach your LAN.

---

## Optional: Run exit node in a VM or on TrueNAS

- **VM (e.g. on TrueNAS or Proxmox):** Use a small Linux VM as the exit node. Give it one NIC on your LAN; run Tailscale + Mullvad + routing as above. No need to expose extra ports.
- **TrueNAS host:** Possible in theory (Tailscale + WireGuard on the host), but TrueNAS is appliance-style; a separate VM or Pi is usually easier to maintain.

---

## Reference

- **Exit nodes (Headscale):** [headscale.net/exit-node](https://headscale.net/exit-node/)
- **Tailscale exit nodes:** [tailscale.com/kb/1103/exit-nodes](https://tailscale.com/kb/1103/exit-nodes/)
- **Full Nix + Mullvad + Headscale exit node:** [r6.technology – Home networking with Headscale and Mullvad exit node](https://r6.technology/posts/home-networking-with-headscale-and-mullvad-exit-node/)
- **Mullvad WireGuard:** [mullvad.net](https://mullvad.net) → Account → WireGuard

---

## Summary checklist

- [ ] Linux exit node: Tailscale installed, `--login-server` + `--advertise-exit-node` + pre-auth key; IP forwarding enabled.
- [ ] Exit node: Mullvad WireGuard up; default route via `wg0`; routes for LAN and Headscale via LAN gateway; NAT out `wg0`.
- [ ] Headscale: `headscale nodes approve-routes --identifier <NODE_ID> --routes 0.0.0.0/0`.
- [ ] Clients: “Use exit node” → select this node; internet goes via Mullvad; LAN still reachable via UDM Pro subnet routes.
