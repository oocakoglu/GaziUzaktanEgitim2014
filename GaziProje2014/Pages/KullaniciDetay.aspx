<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="KullaniciDetay.aspx.cs" Inherits="GaziProje2014.Pages.KullaniciDetay" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <style type="text/css">
        .Tablolar
        {
            width: 550px;
            background-color: Red;
        }
        
        .StyleBaslik
        {
            width: 110px;
        }
        .StyleContent
        {
            width: 164px;
        }
        .AltTablo
        {
            padding-top: 3px;
            padding-bottom: 3px;
            padding-right: 20px;
            float: right;
        }
    </style>

</head>
<body>
    <form id="form1" runat="server">

        <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server" EnablePageHeadUpdate="False">
            <AjaxSettings>
                <telerik:AjaxSetting AjaxControlID="RadAjaxManager1">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="RadImageEditor1" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
            </AjaxSettings>
        </telerik:RadAjaxManager>
        <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">
            <script type="text/javascript">
                function CloseAndRebind(args) {
                    GetRadWindow().BrowserWindow.refreshGrid(args);
                    GetRadWindow().close();
                }

                function GetRadWindow() {
                    var oWindow = null;
                    if (window.radWindow) oWindow = window.radWindow;
                    else if (window.frameElement.radWindow)
                        oWindow = window.frameElement.radWindow;
                    return oWindow;
                }

                function CancelEdit() {
                    GetRadWindow().close();
                }

                function OnClientFilesUploaded(sender, args) {
                    $find('<%=RadAjaxManager1.ClientID %>').ajaxRequest();
            }
            </script>
        </telerik:RadCodeBlock>
        <%--        <telerik:RadWindow ID="wdwKullaniciList" VisibleOnPageLoad="true" runat="server" Title="Kullanıcı Listesi"
               Height="500px"  Width="600px">
              <ContentTemplate>--%>
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server">
        </telerik:RadScriptManager>
        <%--            <telerik:RadSkinManager ID="RadSkinManager1" runat="server" Skin="Silk">
            </telerik:RadSkinManager>--%>
        <fieldset>
            <legend>Kişisel Bilgiler</legend>
            <table>
                <tr>
                    <td colspan="2" rowspan="5" style="width: 270px;">
                        <table style="text-align: center; vertical-align: middle; width: 100%; height: 100%;">
                            <tr>
                                <td>
                                    <asp:Image ID="Image1" runat="server" Height="120px" Width="90px" />
                                </td>
                            </tr>
                        </table>
                    </td>
                    <td class="StyleBaslik">Tipi :
                    </td>
                    <td class="StyleContent">
                        <telerik:RadComboBox ID="cbKullaniciTipleri" runat="server">
                        </telerik:RadComboBox>
                    </td>
                </tr>
                <tr>
                    <td class="StyleBaslik">Kullancı Adı
                    </td>
                    <td class="StyleContent">
                        <telerik:RadTextBox ID="txtKullaniciAdi" runat="server">
                        </telerik:RadTextBox>
                    </td>
                </tr>
                <tr>
                    <td class="StyleBaslik">Şifre
                    </td>
                    <td class="StyleContent">
                        <telerik:RadTextBox ID="txtSifre" runat="server">
                        </telerik:RadTextBox>
                    </td>
                </tr>
                <tr>
                    <td class="StyleBaslik">Adı
                    </td>
                    <td class="StyleContent">
                        <telerik:RadTextBox ID="txtAdi" runat="server">
                        </telerik:RadTextBox>
                    </td>
                </tr>
                <tr>
                    <td class="StyleBaslik">Soyadı
                    </td>
                    <td class="StyleContent">
                        <telerik:RadTextBox ID="txtSoyadi" runat="server">
                        </telerik:RadTextBox>
                    </td>
                </tr>
                <tr>
                    <td colspan="2">
                        <%--<telerik:radupload id="RadUpload1" targetfolder="~/uploads/" allowedfileextensions=".jpg,.jpeg,.gif,.png"
    onclientfileselected="OnClientFileSelectedHandler" runat="server" Height="18px" 
                                Width="247px"></telerik:radupload>--%>
                        <asp:FileUpload ID="FileUpload1" runat="server" Width="182px" />
                    </td>
                    <td class="StyleBaslik">Cinsiyet
                    </td>
                    <td class="StyleContent">
                        <telerik:RadComboBox ID="RadComboBox2" runat="server">
                            <Items>
                                <telerik:RadComboBoxItem runat="server" Text="Erkek" Value="1" />
                                <telerik:RadComboBoxItem runat="server" Text="Kadın" Value="0" />
                            </Items>
                        </telerik:RadComboBox>
                    </td>
                </tr>
                <tr>
                    <td colspan="2">
                        <asp:Button ID="btnYukle" runat="server" Text="Yükle" Width="67px"
                            Height="22px" OnClick="btnYukle_Click" />
                    </td>
                    <td class="StyleBaslik">Doğum Tarihi
                    </td>
                    <td class="StyleContent">
                        <telerik:RadDateTimePicker ID="dteDogumTarihi" runat="server">
                        </telerik:RadDateTimePicker>
                    </td>
                </tr>
            </table>
        </fieldset>
        <fieldset>
            <legend>İletişim Bilgileri</legend>
            <table>
                <tr>
                    <td class="StyleBaslik">Cep Tel No:
                    </td>
                    <td class="StyleContent">
                        <telerik:RadTextBox ID="txtCepTel" runat="server">
                        </telerik:RadTextBox>
                    </td>
                    <td class="StyleBaslik">Ev Tel No:
                    </td>
                    <td class="StyleContent">
                        <telerik:RadTextBox ID="txtEvTel" runat="server">
                        </telerik:RadTextBox>
                    </td>
                </tr>
                <tr>
                    <td class="StyleBaslik">E mail
                    </td>
                    <td class="StyleContent">
                        <telerik:RadTextBox ID="txtemail" runat="server">
                        </telerik:RadTextBox>
                    </td>
                    <td class="StyleBaslik"></td>
                    <td class="StyleContent"></td>
                </tr>
            </table>
        </fieldset>
        <fieldset>
            <legend>Adres Bilgileri</legend>
            <table>
                <tr>
                    <td class="StyleBaslik">Tipi :
                    </td>
                    <td class="StyleContent">
                        <telerik:RadComboBox ID="cbIlAdi" runat="server" OnSelectedIndexChanged="cbIlAdi_SelectedIndexChanged"
                            AutoPostBack="True">
                        </telerik:RadComboBox>
                    </td>
                    <td class="StyleBaslik">Tipi :
                    </td>
                    <td class="StyleContent">
                        <telerik:RadComboBox ID="cbIlceAdi" runat="server">
                        </telerik:RadComboBox>
                    </td>
                </tr>
                <tr>
                    <td class="StyleBaslik">Adres:
                    </td>
                    <td colspan="3">
                        <telerik:RadTextBox ID="txtAdres" runat="server" TextMode="MultiLine" Width="436px">
                        </telerik:RadTextBox>
                    </td>
                </tr>
            </table>
        </fieldset>
        <table class="AltTablo">
            <tr>
                <td style="text-align: left;">
                    <asp:CheckBox ID="chkOnay" Text="Onay" runat="server" />
                </td>
                <td class="tdCellBaslik">
                    <telerik:RadButton ID="btnGuncelle" runat="server" Text="Güncelle" OnClick="btnGuncelle_Click">
                    </telerik:RadButton>
                </td>
                <td class="tdCellBaslik">
                    <telerik:RadButton ID="btnSil" runat="server" Text="Sil" >
                    </telerik:RadButton>
                </td>
            </tr>
        </table>

    </form>
</body>
</html>
