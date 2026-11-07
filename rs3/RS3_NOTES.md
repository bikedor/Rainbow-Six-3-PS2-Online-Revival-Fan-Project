# Rainbow Six 3 (PS2, SLUS-20883) — revival notes

## Disc findings (NTSC-U, SYSTEM.CNF VER 1.01)

- `SLUS_208.83` is only a loader. The game code is in `MP.SOZ` (multiplayer) and `SP.SOZ` (single player):
  4-byte little-endian uncompressed size, then a zlib stream.
- Online bootstrap is the same as Chaos Theory:
  `GET /gsinit.php?user=<name>&dp=<...> HTTP/1.1` to `gsconnect.ubisoft.com`, which returns a `[Servers]` ini
  (`RouterIP%d`, `RouterPort%d`, `RouterLauncherPort%d`, `CDKeyServerIP%d/Port`, `ProxyIP%d/Port`,
  `NATServerIP%d/Port`, `IRCIP%d/Port`).
- Hardcoded hosts: `gsconnect.ubisoft.com`, `gsnat.ubisoft.com`. Both are covered by the existing
  `ubisoft.com` DNS suffix override.
- `GSROUTER.DAT` on the disc points to Ubisoft dev servers (`gsdev-mtl.ubisoft.com`, router 40000, launcher 40005,
  IRC `gschat-dev` 6667, NAT 45000). The game never refers to it, so it can be ignored.
- Identifiers:
  - game name `RAINBOWSIX3PS2US` (Chaos Theory: `SPLINTERCELL3PS2US`)
  - version `RSPS21.0` / `1.0`
  - lobby/group string `RAVENSHIELDPS2`
- GS client is the same SDK family: SRP, GSXor, Blowfish, RSA, router -> wait module -> proxy -> lobby/arena.
  Message names: LOGINWAITMODULE, JOINWAITMODULE, LOBBYSERVERLOGIN, CREATESESSION/JOINSESSION, GROUPINFO,
  GETGROUPINFO, LOGINFRIENDS/ADDFRIEND, STILLALIVE, UPDATESESSIONSTATE, ladder queries, clan manager.
- In-match traffic is Unreal Engine 2 (HELLO / LOGIN / CHALLENGE / WELCOME / NETSPEED), peer to peer between players.
- DNAS: `IRX/DNAS280.IMG` + `OVL/DNAS_R.OVL` (DNAS 2.80). The DNAS server names are encrypted inside the image.

## Files added for RS3

| File | Purpose |
|---|---|
| `RS3 Server.bat` | LAN launcher. Same stack as `SCOPS Server.bat` [L], plus `SCCT_GSINIT_FILE=gsinit_rs3.php` and `SCCT_FRIEND_GAME=RAINBOWSIX3PS2US`. Moves old logs to `_archive\logs_before_rs3_<time>` first. |
| `gsinit_rs3.php` | Copy of `gsinit_diag_localweb.php` with an RS3 welcome message. |
| `rs3\collect_rs3_logs.bat` | Zips `logs\` and the dnasrep log into `rs3\runs\` after a test. |

No existing Chaos Theory file was changed. `state\users.json` is shared, so CT accounts can also sign in to RS3.
Run only one game's server at a time.

## Test 1: first contact

1. Double-click `RS3 Server.bat`.
2. PCSX2 (ABC) with DNS 192.168.1.113. Boot RS3, go to Online and try to sign in with an existing account.
3. Write down the exact on-screen message and the screen it stops on.
4. Press a key in the launcher window to stop. Run `rs3\collect_rs3_logs.bat`.

### Where to look, in order

1. `logs\dns_53.log`: did it ask for `gsconnect.ubisoft.com` / DNAS hosts and get 192.168.1.113?
2. dnasrep window / `dnasrep_test\dnasrep_443.log`: did DNAS pass?
3. `logs\gs_http_80.log`: did `/gsinit.php` arrive (note the `user` and `dp` values)?
4. `logs\router_40000.log`: key exchange and LOGIN.
5. `logs\router_wm_40005.log`: wait module, lobby login, then `FIND_GAME` should show `RAINBOWSIX3PS2US`.

The first step that fails is the next thing to fix.

## Test 1 result (ABC on PCSX2)

- DNAS passed (dnasrep fallback works for RS3).
- `/gsinit.php?user=ABC&dp=RAINBOWSIX3PS2US` served.
- Router 40000: key exchange OK, LOGIN `['ABC','AAAAAAA','RSPS21.0',b'\x01']` accepted, JOINWAITMODULE answered with
  `[']', ['192.168.1.113', u32le 40005]]`.
- The game never connected to 40005 and sat on "Authenticating user ID and password...".
- Game code check (MP.SOZ, loaded at 0x100000): the router JOINWAITMODULE parser (0x4119c0) expects exactly
  `[b']', [ip string, 4-byte binary port]]`, so the reply format is right. The Chaos Theory "ct34" extra frames
  sent with LOGIN/JWM (PROXY_HANDLER persistantdata, LOGINWAITMODULE 0x4e, extra GSSUCCESS) are the main suspect.
- The lobby/proxy wait-module parser (0x452e00) reads `[str, ip string, port as decimal string]`. That will matter
  once RS3 reaches the proxy.

## Test 2

`RS3 Server.bat` now starts `rs3\run_rs3_stack.bat` with `RS3_CT34=off` (plain LOGIN / JOINWAITMODULE replies).
Edit `RS3_CT34` in `RS3 Server.bat` to `ct_ps2` to go back to the Chaos Theory behaviour.

## Test 2 result

Got much further: wait module 40005 (LOGINWAITMODULE, lobby LOGIN with `RAINBOWSIX3PS2US`, LOGINFRIENDS, IGNORELIST,
PLAYERINFO, MOTD), NAT 45000 (`['ABC','RAINBOWSIX3PS2US','RSPS21.0']`, PING/ADDRESS OK), IRC connect to 6668,
ladder module 44002 (LOGIN `['ABC','RSPS21.0']`, JOINWAITMODULE).
Stall cause: with ct34 off, the WM server's `--ct34-host` default `192.168.0.213` was handed to the game as the
proxy/lobby address. Fix: `--ct34-host` now defaults to `--proxy-ip` (backup: `tools\ubigs_router_wm_server.py.pre_rs3`).
Chaos Theory is unaffected (the ct_ps2 profile already set it to `--proxy-ip`).
Cosmetic for later: lobby name/URL and MOTD still say Splinter Cell.

## Test 3/4: "Service is not available now" after the ladder step

Game code (ladder client object, results at 0x485940):
- 4 "find me" queries (type 1, modes 0-3): success or error -10 (not ranked) both accepted.
- Top 10 (type 3, mode 0, processor 0x485410): every row must have GLOBAL_RANK, ALIAS, COUNTRY_ID and RATING.
  The game only *asks* for ALIAS/GLOBAL_RANK/RATING, so the original server must have always added COUNTRY_ID.
- "My level" queries (type 2, modes 1-3, processor 0x485250): need ALIAS and LEVEL.
- Field name table at 0x58f4c0: GLOBAL_RANK, ALIAS, LEVEL, RATING, FRAGSCORE, KILLS, DEATHS, RATIO, TEAMKILLS,
  ROUND, TEAMROUND, TEAMWIN, TEAMRATIO, TIMEPLAYED, COUNTRY_ID.
Fix: `SCCT_LADDER_EXTRA_COLS=COUNTRY_ID` (set in `rs3\run_rs3_stack.bat`) appends COUNTRY_ID to ladder replies.

## 2026-11-02: own folder

RS3 now runs from `C:\RB6 PS2 Server Revive` as a standalone copy of the server (tools, ubi-gs, ubi-gs-new,
dnasrep, webroot, accounts/friends copied from `C:\scops2_server_revive`). From here on RS3 changes are made only
in this folder. RS3 has its own news text (`state\motd.txt`, `state\motd_ubi.txt`) and ranking file
(`state\rs3_ladder_stats.json`).

## Rooms and player records (pt6 test)

- RS3 treats a group id <= 0 as a room and > 0 as a lobby. `SCCT_ROOM_ID_SIGN=neg` makes room ids -100, -101, ...
  (positive ids made the game think the player joined a lobby: 0/6 in the match list, PLAYERS list never cleared).
- MEMBER_JOIN (50) field 1 is the spectator flag; players send "0" (`SCCT_RS3_MEMBER_FLAG`).
- A MEMBER_JOIN for a player already known replaces the record (0x403070) and leaves the old pointer in the room
  player list: garbage names in the PLAYERS tab. In a room the server now sends PLAYER_INFO_UPDATE (66) = [name, info],
  and MEMBER_LEAVE (51) = [name, room id] before moving a player back to the lobby.
- The room count comes from member records, so rooms start at 0 and the room list is pushed before members.
- PLAYER_KICK (10) = [room, name, reason] from the host is not handled by the server yet.

## pt7 test (2026-11-02 16:54-17:10) and next steps

- Negative room ids work: rooms -100 (ABC host) and -101 (DORTEST host) created, joined both ways, 5 rounds started.
- In-room updates now go out as PLAYER_INFO_UPDATE (66); MEMBER_LEAVE (51) is sent on room leave.
- Open: when the HOST closes a room, the joiner does not send GROUP_LEAVE (8); it only sends GROUP_INFO_GET (9)
  on its way back to the lobby. The server kept DORTEST in dead room -100 for 1.5 min (fixed itself on the next join).
  Fix: on room removal, send 51 [name, room] + 50 back to lobby for every member still in that room.
- Still to do: PLAYER_KICK (10) handling (KICK_OUT 61 format), lobby chat (6668), Settings placeholders,
  RS3 match result layout (ranking), PERMIT PING reversed address (internet play), internet-mode launcher.

## Country field on player profiles (started 2026-11-03, fixed 2026-11-07)

- The Settings/profile "findme3..findme7" placeholders and the "Country" shown when viewing another player
  are the SAME reply: ubi-gs/ubi-gs-master/gsm.py PlayerInfoResponse (the copy actually on sys.path --
  ubigs_common.py's UBI_GS_ROOT points at ubi-gs/ubi-gs-master, not ubi-gs-new, which is an unused leftover
  copy), built in ubigs_router_wm_server.py where gsm.MESSAGE_TYPE.PLAYERINFO is handled.
  player_data = [nick, real_name, findme3, findme4, findme5, findme6, findme7]. findme3 = Country
  (confirmed from in-game strings "FIRST NAME:"/"LAST NAME:"/"CONUTRY:" at MP.SOZ 0x51b6b0).
- First pass (2026-11-07, superseded below): checked every message a GET/view could trigger and found no
  country value anywhere -- LOGIN, LOBBY_MSG LOGIN subtype 21, SET_PLAYER_INFO's 24-byte blob, the
  LADDER_MODULE query type '1' (`_cols` comes back empty), CREATE_ROOM subtype 23, room subtype 15.
  Wrongly concluded from this that the client never transmits country at all. That was only true of the
  *read* path -- it does transmit it on a *save*, just via a message nothing had looked at yet (next point).
- Actual mechanism: Personal Settings' "Warning! You are about to send these details over the network. Are
  you sure?" confirm box, on OK, sends it as part of MODIFYUSER (0x62) -- the SAME message used for password
  changes. DL format (documented in-code already, from an earlier round): `['', password, first_name,
  last_name, email, country]`. The handler was only ever reading lst[1] (password); lst[2..5] (first name,
  last name, email, country) were silently dropped -- that's why Country (and First/Last Name) always came
  back blank. The in-game "Modify Country" picker (UC_MSGBOX_MODIFYCOUNTRY, B_country/P_country/L_country
  widgets, `countrycodes.txt` list) is just the UI for building this same Personal Settings payload, not a
  dead end as first thought. `COUNTRY_ID` elsewhere in the binary is a separate thing -- a ladder-stats
  column name the client *requests* for the Top 10 screen (SCCT_LADDER_EXTRA_COLS), never uploaded.
- Fix applied: `tools/ubigs_router_wm_server.py`'s MODIFYUSER handler now also saves first_name/last_name/
  email/country (lst[2..5]) into the logged-in user's record in `state/rs3_ladder_stats.json`
  (FIRST_NAME/LAST_NAME/EMAIL/COUNTRY_CODE), and PLAYERINFO reads them back out instead of the literal
  "findme3" string.
  - `ubi-gs/ubi-gs-master/gsm.py`: `PlayerInfoResponse` takes optional `nick`/`real_name` (for First/Last
    Name) and an `extra` list (up to 5 values for findme3..findme7); anything not supplied keeps the
    original placeholder, so other callers/projects sharing this file are unaffected.
  - `tools/ubigs_router_wm_server.py`: `_rs3_player_record(name)` reads the stored profile dict;
    `_rs3_player_country(name)` returns COUNTRY_CODE (falling back to a non-zero COUNTRY_ID, then None to
    keep the placeholder); `_rs3_player_name(name)` returns (FIRST_NAME, LAST_NAME). The PLAYERINFO
    handler also now logs the request's raw `msg.dl` and, if it's a non-empty string, treats it as the
    *target* player's name (viewing someone else's profile) instead of always answering with the
    connecting client's own username -- this was untested since no pt6/pt7 capture showed a PLAYERINFO
    request's DL contents; the log line will confirm on the next test whether that assumption is right.
  - Not yet touched: findme4-findme7 (GAME NAME / PLAYER NAME / etc. placeholders) -- same mechanism,
    just need their field meanings confirmed the way Country was.
