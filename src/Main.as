const string PluginName = Meta::ExecutingPlugin().Name;
const string MenuIconColor = "\\$df5";
const string PluginIcon = Icons::ArrowsH;
const string MenuTitle = MenuIconColor + PluginIcon + "\\$z " + PluginName;


[Setting hidden]
bool g_Window = true;


void RenderMenu() {
    if (UI::MenuItem(MenuTitle, "", g_Window)) {
        g_Window = !g_Window;
    }
}


void Render() {
    if (!g_Window) return;
    UI::SetNextWindowSize(700, 400, UI::Cond::FirstUseEver);
    if (UI::Begin(PluginName, g_Window)) {
        UI::BeginTabBar("util tabs", UI::TabBarFlags::Reorderable);
        if (UI::BeginTabItem("WSID -> Login")) {
            DrawWsidToLoginTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Login -> WSID")) {
            DrawLoginToWsidTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("WSID -> Display Name")) {
            DrawWSIDToDisplayNameTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Login -> Display Name")) {
            DrawLoginToDisplayNameTab();
            UI::EndTabItem();
        }
        UI::EndTabBar();
    }
    UI::End();
}
