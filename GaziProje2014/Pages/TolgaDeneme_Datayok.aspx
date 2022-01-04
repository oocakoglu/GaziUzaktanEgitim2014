<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TolgaDeneme_Datayok.aspx.cs" Inherits="GaziProje2014.Pages.TolgaDeneme_Datayok" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server">
            <Scripts>
                <asp:ScriptReference Assembly="Telerik.Web.UI" Name="Telerik.Web.UI.Common.Core.js">
                </asp:ScriptReference>
                <asp:ScriptReference Assembly="Telerik.Web.UI" Name="Telerik.Web.UI.Common.jQuery.js">
                </asp:ScriptReference>
                <asp:ScriptReference Assembly="Telerik.Web.UI" Name="Telerik.Web.UI.Common.jQueryInclude.js">
                </asp:ScriptReference>
            </Scripts>
        </telerik:RadScriptManager>
    <div>
    <telerik:RadTabStrip ID="RadTabStrip1" runat="server" MultiPageID="RadMultiPage1" Skin="MetroTouch" SelectedIndex="0" Align="Justify">
            <Tabs>
                <telerik:RadTab Text="Grid1"></telerik:RadTab>
                <telerik:RadTab Text="Grid2"></telerik:RadTab>                
            </Tabs>
        </telerik:RadTabStrip>
        <telerik:RadMultiPage ID="RadMultiPage1" runat="server" SelectedIndex="0">
            <telerik:RadPageView ID="RadPageView1" runat="server" Height="700px" >
                <telerik:RadGrid ID="RadGrid1" runat="server" CellSpacing="-1" GridLines="Both">
                    <ClientSettings>
                        <Selecting AllowRowSelect="True" />
                    </ClientSettings>
                </telerik:RadGrid>
            </telerik:RadPageView>
            <telerik:RadPageView ID="RadPageView2" runat="server" Height="700px" >
                <telerik:RadGrid ID="RadGrid2" runat="server">
                    <ClientSettings>
                        <Selecting AllowRowSelect="True" />
                    </ClientSettings>
                </telerik:RadGrid>
            </telerik:RadPageView>
            
        </telerik:RadMultiPage>
    </div>
    </form>
</body>
</html>
