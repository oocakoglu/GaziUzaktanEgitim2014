<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="KullaniciBilgisi.aspx.cs" Inherits="GaziProje2014.Forms.KullaniciBilgisi" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


    <style>
        .StyleBaslik {
            width: 110px;
        }

        .StyleContent {
            width: 164px;
        }

        .KullaniciBilgisiContent {
            position: absolute;
            top: 0px;
            left: 0px;
            right: 0px;
            bottom: 36px;
            overflow: scroll;
            overflow-x: hidden;
            padding-top: 20px;
            padding-left: 30px;
            /*background-color:green;*/
        }


        .ParentPanel {
            width: 590px;
        }

        .legendForm {
            padding: 4px;
            position: absolute;
            left: 10px;
            top: -11px;
            background-color: #2DABC1; /*#4F709F;*/
            color: white;
            -webkit-border-radius: 4px;
            -moz-border-radius: 4px;
            border-radius: 4px;
            box-shadow: 2px 2px 4px #888;
            -moz-box-shadow: 2px 2px 4px #888;
            -webkit-box-shadow: 2px 2px 4px #888;
            text-shadow: 1px 1px 1px #333;
        }

        .fieldsetForm {
            position: relative;
            padding: 10px;                
            margin-bottom: 30px;
            background: #F6F6F6;
            -webkit-border-radius: 8px;
            -moz-border-radius: 8px;
            border-radius: 8px;
            background: -webkit-gradient(linear, left top, left bottom, from(#EFEFEF), to(#FFFFFF));
            background: -moz-linear-gradient(center top, #EFEFEF, #FFFFFF 100%);
            box-shadow: 3px 3px 10px #ccc;
            -moz-box-shadow: 3px 3px 10px #ccc;
            -webkit-box-shadow: 3px 3px 10px #ccc;
        }
    </style>

    <div class="KullaniciBilgisiContent">
       
         <div class="ParentPanel">
            <fieldset class="fieldsetForm">
                <legend class="legendForm">Kişisel Bilgiler</legend>
                <table>
                    <tr>
                        <td colspan="2" rowspan="5" style="width: 274px;">
                            <table style="text-align: center; vertical-align: middle; width: 100%; height: 100%;">
                                <tr>
                                    <td>
                                        <asp:Image ID="ImgProfilResim" runat="server" Height="120px" Width="90px" />
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
                            <asp:FileUpload ID="flupldResim" runat="server" Width="182px" />
                        </td>
                        <td class="StyleBaslik">Cinsiyet
                        </td>
                        <td class="StyleContent">
                            <telerik:RadComboBox ID="cbCinsiyet" runat="server">
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
            <fieldset class="fieldsetForm">
                <legend  class="legendForm">İletişim Bilgileri</legend>
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
            <fieldset class="fieldsetForm">
                <legend  class="legendForm">Adres Bilgileri</legend>
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
        </div>
        <asp:HiddenField ID="hdnResimUrl" runat="server" />
    </div>

    <div class="contentAlt30">
        <telerik:RadButton Width="130px" ID="btnKaydet" runat="server" Text="Bilgilerimi Güncelle" OnClick="btnKaydet_Click"></telerik:RadButton>
    </div>
    <div class="contentAlt30Golge"> 
    </div>

    <telerik:RadNotification ID="RadNotification1" runat="server" EnableRoundedCorners="true"
        EnableShadow="true" Text="Sample content" Title="Bilgilendirme" Width="300" Height="100">
    </telerik:RadNotification>

</asp:Content>
