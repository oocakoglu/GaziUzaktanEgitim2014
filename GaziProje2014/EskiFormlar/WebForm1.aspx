<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="WebForm1.aspx.cs" Inherits="GaziProje2014.Forms.WebForm1" %>
<%@ Register TagPrefix="telerik" Namespace="Telerik.Web.UI" Assembly="Telerik.Web.UI" %>


<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <link href="Styles.css" rel="stylesheet" />
</head>
<body>
    
    <form id="form1" runat="server">

         <telerik:RadScriptManager runat="server" ID="RadScriptManager1" />
            <telerik:RadSkinManager ID="QsfSkinManager" runat="server" ShowChooser="true" />
            <telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">
                <script type="text/javascript">
                    function selectVideo(divEl, index) {
                        var listView = $find("<%= RadListView1.ClientID %>");
                        listView.fireCommand("Select", index);
                    }
                    function selectSong(divEl, index) {
                        var listView = $find("<%= RadListView2.ClientID %>");
                        listView.fireCommand("Select", index);
                    }
                </script>
            </telerik:RadScriptBlock>
            <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server">
                <div class="mediaPlayerWrapper">
                    <div class="leftPanel">
                        <telerik:RadMediaPlayer ID="RadMediaPlayer1" runat="server" Width="700px" BackColor="Black"
                            StartVolume="80" Height="394px">
                        </telerik:RadMediaPlayer>
                    </div>
                    <div style="background-color: #10191E; border-left: 1px solid #364046;">
                        <telerik:RadTabStrip ID="RadTabStrip1" runat="server" Skin="Glow" MultiPageID="RadMultiPage1"
                            SelectedIndex="0" Width="246px" CssClass="tabStripMenu">
                            <Tabs>
                                <telerik:RadTab Text="Video" Value="Video" Selected="true" PageViewID="RadPageView1">
                                </telerik:RadTab>
                                <telerik:RadTab Text="Audio" Value="Audio" PageViewID="RadPageView2"></telerik:RadTab>
                                <telerik:RadTab Text="YouTube" Value="YouTube" PageViewID="RadPageView3"></telerik:RadTab>
                            </Tabs>
                        </telerik:RadTabStrip>
                        <telerik:RadMultiPage ID="RadMultiPage1" runat="server" SelectedIndex="0" Height="358px" BackColor="#10191E">
                            <telerik:RadPageView ID="RadPageView1" runat="server" Selected="true" Style="padding-top: 1px;">
                                <telerik:RadListView ID="RadListView1" runat="server" OnSelectedIndexChanged="RadListView1_SelectedIndexChanged" OnNeedDataSource="RadListView1_NeedDataSource">
                                    <LayoutTemplate>
                                        <div id="itemPlaceholder" runat="server">
                                        </div>
                                    </LayoutTemplate>
                                    <ItemTemplate>
                                        <a href="#" class="playlistItem" onclick='<%#"selectVideo(this,"+Container.DisplayIndex+"); return false;"%>'>
                                            <asp:Image ID="Image1" runat="server" AlternateText='<%# Eval("Title") %>' ImageUrl='<%# "image/" + Eval("Path") + ".png"%>' />
                                            <asp:Label ID="Label1" runat="server" Text='<%# Eval("Title") %>'></asp:Label>
                                        </a>
                                    </ItemTemplate>
                                    <SelectedItemTemplate>
                                        <span class="playlistItem selected">
                                            <asp:Image ID="Image2" runat="server" AlternateText='<%# Eval("Title") %>' ImageUrl='<%# "image/" + Eval("Path") + ".png"%>' />
                                            <asp:Label ID="Label2" runat="server" Text='<%# Eval("Title") %>'></asp:Label>
                                            <asp:Image ID="Image3" CssClass="playIcon" runat="server" ImageUrl="~/Media-Player/Examples/Functionality/MediaTypes/Image/playIcon.png"
                                                AlternateText="Selected" />
                                        </span>
                                    </SelectedItemTemplate>
                                </telerik:RadListView>
                            </telerik:RadPageView>
                            <telerik:RadPageView ID="RadPageView2" runat="server" Style="padding-top: 1px;">
                                <telerik:RadListView ID="RadListView2" runat="server" OnSelectedIndexChanged="RadListView2_SelectedIndexChanged" OnNeedDataSource="RadListView2_NeedDataSource">
                                    <LayoutTemplate>
                                        <div id="itemPlaceholder" runat="server">
                                        </div>
                                    </LayoutTemplate>
                                    <ItemTemplate>
                                        <a href="#" class="playlistItem playlistAudioItem" onclick='<%#"selectSong(this,"+Container.DisplayIndex+"); return false;"%>'>
                                            <asp:Label ID="Label3" runat="server" Text='<%# Eval("Title") %>'></asp:Label>
                                        </a>
                                    </ItemTemplate>
                                    <SelectedItemTemplate>
                                        <span class="playlistItem playlistAudioItem selected">
                                            <asp:Image ID="Image4" CssClass="playIcon" runat="server" ImageUrl="~/Media-Player/Examples/Functionality/MediaTypes/Image/playIcon.png"
                                                AlternateText="Selected" />
                                            <asp:Label ID="Label4" runat="server" Text='<%# Eval("Title") %>'></asp:Label>
                                        </span>
                                    </SelectedItemTemplate>
                                </telerik:RadListView>
                            </telerik:RadPageView>
                            <telerik:RadPageView ID="RadPageView3" runat="server">
                                <div style="padding: 16px 0 0 1px;">
                                    <asp:Image ID="Image5" runat="server" AlternateText="YouTube"
                                        ImageUrl="~/Media-Player/Examples/Functionality/MediaTypes/Image/youtubeLogo.png" Width="75px" Height="32px" />
                                    <br />
                                    <br />
                                    <div
                                        style='color: #B4BEC3; font-family: Arial,​Helvetica,​sans-serif; font-size: 13px; margin-bottom: -11px;'>
                                        Insert your YouTube URL
                                    </div>
                                    <br />
                                    <telerik:RadTextBox ID="RadTextBox1" runat="server" Skin="Glow" Width="199px"
                                        Height="28px" Text="https://www.youtube.com/watch?v=oy4NTWpjHjM">
                                    </telerik:RadTextBox>
                                    <telerik:RadButton ID="RadButton1" runat="server" Text="YouTube" BackColor="#2C363B" AutoPostBack="true" OnClick="RadButton1_Click"
                                        Style="margin: 0 0 -11px 10px; background-repeat: no-repeat;" Width="30px" Height="28px">
                                        <Image EnableImageButton="true" ImageUrl="~/Media-Player/Examples/Functionality/MediaTypes/Image/buttonNormal.png"
                                            HoveredImageUrl="~/Media-Player/Examples/Functionality/MediaTypes/Image/buttonHover.png" />
                                        <Image EnableImageButton="true" />
                                    </telerik:RadButton>
                                </div>
                            </telerik:RadPageView>
                        </telerik:RadMultiPage>
                    </div>
                </div>
            </telerik:RadAjaxPanel>

    </form>
</body>
</html>
