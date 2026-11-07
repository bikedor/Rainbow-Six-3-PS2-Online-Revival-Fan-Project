# Rainbow Six 3 (PS2, SLUS-20883) server revive Claude and Grok AI helped a lot in this.

A standalone, unofficial Ubi.com "GSConnect" (GS) server for *Tom Clancy's Rainbow
Six 3* on PS2, letting the game's original online features (login, friends
list, lobby, ladder/ranking, matchmaking) run again against a server you
control, instead of Ubisoft's long-dead official one.

Built from an earlier server revive for *Splinter Cell: Chaos Theory*; the two
projects share the same GS protocol implementation but run as separate,
independent servers.

**This is a fan preservation project.** It contains no Ubisoft game assets or
copyrighted game code -- only a from-scratch reimplementation of the network
protocol the retail disc already speaks, plus a small country-name lookup
table reconstructed from the disc's own data files purely for interoperability
(so the game's own UI displays correctly). You need your own legally obtained
copy of the game to use this.

## Requirements

- Windows (the launcher scripts are `.bat`/PowerShell; the server itself is
  plain Python and could run elsewhere with adaptation)
- Python 3.9+
- `pip install -r requirements.txt`
- An OpenSSL build on `PATH` (used for some of the crypto setup)
- PCSX2 (emulator) or a real PS2 with a way to point its DNS at this server

## Quick start

1. Double-click **`RS3 Server.bat`** (it will ask for administrator rights --
   needed to open firewall ports and bind privileged ports like 80/443).
3. It will:
   - auto-detect this PC's LAN IP address (no manual editing needed),
   - open the Windows Firewall ports the server needs,
   - start the server stack and the DNAS helper,
   - print the LAN IP to use.
4. On PCSX2 (or your PS2's network settings), set the **DNS server** to the IP
   address the launcher printed.
5. Boot Rainbow Six 3, go to Online / Ubi.com, and sign in.
6. Press any key in the launcher window (or close it) to stop everything.
7. `rs3\collect_rs3_logs.bat` zips the logs into `rs3\runs\` if you want to
   save or share a run for debugging.

Only run one server at a time (RS3 or Chaos Theory, if you have both) -- they
use the same ports.

### Playing over the internet instead of LAN

Off by default. To enable it, open `RS3 Server.bat` in a text editor and set
`SCCT_ALLOW_PUBLIC=1` near the top (leave `SCCT_PUBLIC_IP` blank to have it
auto-detected, or set it yourself). You'll also need to forward the ports
listed in `add_rs3_firewall_rules.bat` on your router. There's no real
authentication here -- only do this with people you trust.

## DNAS replacement

The PS2's console-level network authentication (DNAS) needs a small HTTPS
responder on port 443 that answers with a canned "success" reply instead of
contacting Sony's real (shut-down) servers. This project bundles a tool called
`dnasrep.exe` in `dnasrep_test\`, used via its `-force-success=fallback` mode,
along with the TLS certs/keys it and the main server need (`dnasrep_test\certs\`,
`tools\certs\`) -- the launcher starts everything automatically, no separate
setup step required.

`dnasrep.exe` is a third-party tool from the PS2 online-server-revival
community, included here under its own separate licensing/terms -- if you fork
this repo, keep that in mind before redistributing it elsewhere. It most
likely originated from one of these DNAS-replacement projects (exact source
not confirmed):

- https://github.com/FogNo23/DNASrep
- https://github.com/hashsploit/clank-dnas
- https://github.com/Zackmon/DNASrep
- https://github.com/benjamin238/DNASrep
- https://github.com/carl0sjt/DNASrep
- https://github.com/Project-Crystal-Server/DNAS1Server
- https://github.com/NoTjugotre/dnasrep-go
- https://github.com/FatalityDevelopment/DnaSDK

If you recognize which of these (or another project entirely) this binary
came from, credit/license corrections are welcome.

## Layout

| Path | What |
|---|---|
| `RS3 Server.bat` | Main launcher: detects LAN IP, opens firewall, starts everything |
| `add_rs3_firewall_rules.bat` / `remove_rs3_firewall_rules.bat` | Manual firewall rule management (the launcher already does this automatically; these are for troubleshooting or cleanup) |
| `rs3\run_rs3_stack.bat` | All RS3-specific settings (`SCCT_*` env vars) and the stack start |
| `gsinit_rs3.php` | Server list sent to the game on boot (`/gsinit.php`). Any private IP literal in this file is rewritten on the fly to the server's real current LAN/public IP -- you do not need to edit the IPs in it yourself |
| `tools\` | Server code: router (40000), wait module (40005), ladder/ranking proxy (44002), persistent-data proxy (44001), NAT helper (45000), DNS override forwarder, gsinit HTTP server |
| `ubi-gs\ubi-gs-master\` | [ubi-gs](https://github.com/michal-kapala/ubi-gs) -- MIT-licensed GS protocol library this project is built on (credit: michal-kapala) |
| `dnasrep_test\` | DNAS replacement: `dnasrep.exe`, its TLS certs/keys, and the scripts/config that launch it |
| `tools\certs\` | Self-signed CA and server cert/key used by the main server's own HTTPS bits |
| `state\` | Accounts, friends, ladder stats, MOTD text. Account/ladder files are created fresh on first run (not included in this repo) |
| `rs3\RS3_NOTES.md` | Disc findings, protocol notes, test history for RS3 specifically |
| `webroot\` | Small static files served alongside gsinit (plugin list, games list) |

## Known limitations / open items

- Room close doesn't send `GROUP_LEAVE` to other members yet
- `PLAYER_KICK` / `KICK_OUT` handling is incomplete
- Lobby chat (port 6668) isn't wired up
- Match results aren't recorded to the ranking yet (`SCCT_RANKED_RECORD=0`) --
  the result packet's layout isn't mapped
- PERMIT PING uses a reversed address for internet play in some cases
- The in-game "Personal Settings > Country" field doesn't reflect the saved
  value on reopen (cosmetic -- the same value displays correctly everywhere
  else, e.g. the Ladder/Top 10 screen)
- No internet-mode launcher beyond the manual env-var toggle above

See `rs3\RS3_NOTES.md` for the full history of what's been tried and found.

## Credits

This project builds heavily on other people's work:

- [**ubi-gs**](https://github.com/michal-kapala/ubi-gs) (michal-kapala, MIT
  license) -- the Ubisoft Game Service (GS) protocol library vendored under
  `ubi-gs\ubi-gs-master\`. This server would not exist without it.
- [**scops2_server_revive**](https://github.com/SPEARTECH/scops2_server_revive)
  (SPEARTECH) -- the original Splinter Cell: Chaos Theory server revive this
  RS3 server was forked and adapted from.
- [**scops2_server_revive-gs-Connect**](https://github.com/bikedor/scops2_server_revive-gs-Connect)
  (bikedor) -- further GS-Connect work this project also draws on.

## Contributing / sharing this repo

If you fork or share this:
- **Do not commit** `state\*.json` (live account/ladder data), `logs\`,
  `_archive\`, or `captures\` (runtime output and possibly real packet
  captures). A `.gitignore` covering these is included.
- `tools\certs\` and `dnasrep_test\certs\` are self-signed TLS certs/keys
  bundled here on purpose so the server runs out of the box. They're only
  used to answer the PS2's dead DNAS/auth checks with a canned "success" --
  they have no value outside that, but if you'd rather not ship a shared
  private key in your own fork, delete them and regenerate your own (see
  `tools\certs\ca\openssl.cnf` for the CA setup).
- `dnasrep_test\dnasrep.exe` is a third-party binary bundled here under its
  own separate terms -- see [DNAS replacement](#dnas-replacement) above.
- `tools\country_dump\` is scratch output from a one-off investigation into
  the game's country-ID list and isn't needed to run the server.

## License

This project's own code is released under the MIT License -- see `LICENSE`.
The vendored `ubi-gs` library under `ubi-gs\ubi-gs-master\` carries its own
MIT license file; keep that notice intact if you redistribute it.
