
string m_UtilWsidConv = "";
void DrawWsidToLoginTab() {
    m_UtilWsidConv = UI::InputTextMultiline("WSIDs", m_UtilWsidConv);
    if (UI::Button("Convert")) {
        auto wsids = m_UtilWsidConv.Split("\n");
        m_UtilWsidConv = "";
        for (uint i = 0; i < wsids.Length; i++) {
            auto wsid = wsids[i].Trim();
            if (wsid.Length == 0) continue;
            wsids[i] = WSIDToLogin(wsid);
            m_UtilWsidConv += wsids[i] + "\n";
        }
    }
}

string m_UtilLoginConv = "";
void DrawLoginToWsidTab() {
    m_UtilLoginConv = UI::InputTextMultiline("Logins", m_UtilLoginConv);
    if (UI::Button("Convert")) {
        auto logins = m_UtilLoginConv.Split("\n");
        m_UtilLoginConv = "";
        for (uint i = 0; i < logins.Length; i++) {
            auto login = logins[i].Trim();
            if (login.Length == 0) continue;
            logins[i] = LoginToWSID(login);
            m_UtilLoginConv += logins[i] + "\n";
        }
    }
}

string m_UtilLoginToDisplayName = "";
string m_UtilLoginToDisplayNameRes = "";
bool loadingL2DN = false;
uint l2dnTotal = 0;
uint l2dnDone = 0;
void DrawLoginToDisplayNameTab() {
    UI::BeginDisabled(loadingL2DN);
    m_UtilLoginToDisplayName = UI::InputTextMultiline("Logins", m_UtilLoginToDisplayName);
    if (UI::Button("Get Display Names")) {
        startnew(GetDisplayNamesFromLogins);
    }
    UI::EndDisabled();
    if (loadingL2DN) {
        UI::Text("Loading Display Names...");
        UI::ProgressBar(float(l2dnDone) / float(l2dnTotal), vec2(-1, 0), Text::Format("%.1f %", float(l2dnDone) / float(l2dnTotal) * 100.));
    }
    UI::Separator();
    UI::Text("Result - Display Names:");
    UI::InputTextMultiline("##l2dn-res", m_UtilLoginToDisplayNameRes, vec2(), UI::InputTextFlags::ReadOnly);
}

void GetDisplayNamesFromLogins() {
    loadingL2DN = true;
    m_UtilLoginToDisplayNameRes = "";
    l2dnDone = 0;
    auto logins = m_UtilLoginToDisplayName.Split("\n");
    l2dnTotal = logins.Length;
    auto nbChunks = (logins.Length + 99) / 100;
    for (uint c = 0; c < nbChunks; c++) {
        string[] chunk = {};
        uint nbLogins = Math::Min(100, logins.Length - c * 100);
        uint startIx = c * 100;
        for (uint i = 0; i < nbLogins; i++) {
            string l = logins[startIx + i].Trim();
            if (l.Length == 0) continue;
            chunk.InsertLast(LoginToWSID(l));
        }
        auto res = GetDisplayNames(chunk);
        for (uint i = 0; i < res.Length; i++) {
            m_UtilLoginToDisplayNameRes += res[i] + "\n";
        }
        l2dnDone += nbLogins;
    }
    loadingL2DN = false;
}



string m_UtilWsidToDisplayName = "";
string m_UtilWsidToDisplayNameRes = "";
bool loadingWSID2DN = false;
uint wsid2dnTotal = 0;
uint wsid2dnDone = 0;
void DrawWSIDToDisplayNameTab() {
    UI::BeginDisabled(loadingWSID2DN);
    m_UtilWsidToDisplayName = UI::InputTextMultiline("WSIDs", m_UtilWsidToDisplayName);
    if (UI::Button("Get Display Names##fromwsid")) {
        startnew(GetDisplayNamesFromWSIDs);
    }
    UI::EndDisabled();
    if (loadingWSID2DN) {
        UI::Text("Loading Display Names...");
        UI::ProgressBar(float(wsid2dnDone) / float(wsid2dnTotal), vec2(-1, 0), Text::Format("%.1f %", float(wsid2dnDone) / float(wsid2dnTotal) * 100.));
    }
    UI::Separator();
    UI::Text("Result - Display Names:");
    UI::InputTextMultiline("##l2dn-res", m_UtilWsidToDisplayNameRes, vec2(), UI::InputTextFlags::ReadOnly);
}


void GetDisplayNamesFromWSIDs() {
    loadingWSID2DN = true;
    m_UtilWsidToDisplayNameRes = "";
    wsid2dnDone = 0;
    auto wsids = m_UtilWsidToDisplayName.Split("\n");
    wsid2dnTotal = wsids.Length;
    auto nbChunks = (wsids.Length + 99) / 100;
    for (uint c = 0; c < nbChunks; c++) {
        string[] chunk = {};
        uint nbWSIDs = Math::Min(100, wsids.Length - c * 100);
        uint startIx = c * 100;
        for (uint i = 0; i < nbWSIDs; i++) {
            string l = wsids[startIx + i].Trim();
            if (l.Length == 0) continue;
            chunk.InsertLast(l);
        }
        auto res = GetDisplayNames(chunk);
        for (uint i = 0; i < res.Length; i++) {
            m_UtilWsidToDisplayNameRes += res[i] + "\n";
        }
        wsid2dnDone += nbWSIDs;
    }
    loadingWSID2DN = false;
}


string[]@ GetDisplayNames(string[]@ wsids) {
    auto userMgr = GetApp().UserManagerScript;
    auto userId = userMgr.Users[0].Id;
    MwFastBuffer<wstring> _wsids;
    for (uint i = 0; i < wsids.Length; i++) {
        _wsids.Add(wsids[i]);
    }
    auto req = userMgr.RetrieveDisplayName(userId, _wsids);
    while (req.IsProcessing) yield();
    if (req.HasFailed) {
        warn("Failed to get display names: " + req.ErrorType + " / " + req.ErrorCode + " / " + req.ErrorDescription);
        userMgr.TaskResult_Release(req.Id);
        return {};
    }
    if (req.IsCanceled) {
        warn("Get display names request was canceled");
        userMgr.TaskResult_Release(req.Id);
        return {};
    }
    if (req.HasSucceeded) {
        string[] r = {};
        for (uint i = 0; i < wsids.Length; i++) {
            r.InsertLast(req.GetDisplayName(wsids[i]));
        }
        userMgr.TaskResult_Release(req.Id);
        return r;
    }
    warn("Get display names request unknown state. processing? " + req.IsProcessing);
    userMgr.TaskResult_Release(req.Id);
    return {};
}





string WSIDToLogin(const string &in wsid) {
    try {
        auto hex = string::Join(wsid.Split("-"), "");
        auto buf = HexToBuffer(hex);
        return buf.ReadToBase64(buf.GetSize(), true);
    } catch {
        warn("WSID failed to convert: " + wsid);
        return wsid;
    }
}


string LoginToWSID(const string &in login) {
    try {
        auto buf = MemoryBuffer();
        buf.WriteFromBase64(login, true);
        auto hex = BufferToHex(buf);
        return hex.SubStr(0, 8)
            + "-" + hex.SubStr(8, 4)
            + "-" + hex.SubStr(12, 4)
            + "-" + hex.SubStr(16, 4)
            + "-" + hex.SubStr(20)
            ;
    } catch {
        warn("Login failed to convert: " + login);
        return login;
    }
}

string BufferToHex(MemoryBuffer@ buf) {
    buf.Seek(0);
    auto size = buf.GetSize();
    string ret;
    for (uint i = 0; i < size; i++) {
        ret += Uint8ToHex(buf.ReadUInt8());
    }
    return ret;
}

string Uint8ToHex(uint8 val) {
    return Uint4ToHex(val >> 4) + Uint4ToHex(val & 0xF);
}

string Uint4ToHex(uint8 val) {
    if (val > 0xF) throw('val out of range: ' + val);
    string ret = " ";
    if (val < 10) {
        ret[0] = val + 0x30;
    } else {
        // 0x61 = a
        ret[0] = val - 10 + 0x61;
    }
    return ret;
}

MemoryBuffer@ HexToBuffer(const string &in hex) {
    MemoryBuffer@ buf = MemoryBuffer();
    for (int i = 0; i < hex.Length; i += 2) {
        buf.Write(Hex2ToUint8(hex.SubStr(i, 2)));
    }
    buf.Seek(0);
    return buf;
}

uint8 Hex2ToUint8(const string &in hex) {
    return HexPairToUint8(hex[0], hex[1]);
}


uint8 HexPairToUint8(uint8 c1, uint8 c2) {
    return HexCharToUint8(c1) << 4 | HexCharToUint8(c2);
}

// values output in range 0 to 15 inclusive
uint8 HexCharToUint8(uint8 char) {
    if (char < 0x30 || (char > 0x39 && char < 0x61) || char > 0x66) throw('char out of range: ' + char);
    if (char < 0x40) return char - 0x30;
    return char - 0x61 + 10;
}
