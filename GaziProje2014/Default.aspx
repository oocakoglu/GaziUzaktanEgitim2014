<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="GaziProje2014.Default" %>
<%@ Register TagPrefix="telerik" Namespace="Telerik.Web.UI" Assembly="Telerik.Web.UI" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Web tabanlı Uzaktan Eğitim Sistemi</title>


    <style>

        html 
        {
            background: url(/Style/ArkaPlan.jpg) no-repeat center center fixed;
            -webkit-background-size: cover;
            -moz-background-size: cover;
            -o-background-size: cover;
            background-size: cover;
            height: 100%;
        }

        .GirisPanel {
            padding-bottom:10px;
            padding-top:30px;
            padding-left:30px;
            padding-right:10px;

            position: absolute;
            top: 120px;
            left: 140px;
            width: 340px;
            height: 410px;   
            -moz-border-radius: 50px;
            border-radius: 50px; 
            z-index: 1;                   
        }

        .GirisPanelGolge{
            padding-bottom:10px;
            padding-top:30px;
            padding-left:30px;
            padding-right:10px;

            position: absolute;
            top: 120px;
            left: 140px;
            width: 340px;
            height: 410px;  
            background-color:white;    
            -moz-border-radius: 50px;
            border-radius: 50px;      
            opacity: 0.40; 
            filter: alpha(opacity=40);  
        }
        
        .form-control {
            display: block;
            width: 270px;
            height: 30px;
            padding: 6px 12px;
            font-size: 14px;
            line-height: 1.428571429;
            color: #555555;
            vertical-align: middle;
            background-color: #ffffff;
            /*background-color:#5e7ca0;*/
            background-image: none;
            border: 1px solid #cccccc;
            border-radius: 4px;
            -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075);
            box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075);
            -webkit-transition: border-color ease-in-out 0.15s, box-shadow ease-in-out 0.15s;
            transition: border-color ease-in-out 0.15s, box-shadow ease-in-out 0.15s;
        }

        .Hucre {
            padding: 5px;
        }

        .UstBaslik {
            font-size: 24px;
            font-weight: 100;
            font-style: normal;
        }

        .Girisbutton {
            background-color: #5bc0de;
            width:120px;
            display: inline-block;
            padding: 6px 12px;
            margin-bottom: 0;
            font-size: 14px;
            font-weight: normal;
            line-height: 1.428571429;
            text-align: center;
            white-space: nowrap;
            vertical-align: middle;
            cursor: pointer;
            background-image: none;
            border: 1px solid transparent;
            border-radius: 4px;
            -webkit-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            -o-user-select: none;
            user-select: none;
        }

    </style>
</head>
<body>
    <form id="form1" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server"></telerik:RadScriptManager>

<%--        <div id="background">
            <img src="Style/ArkaPlan.jpg" class="stretch" alt="" />

        </div>--%>


        <div class="GirisPanel">
            <table class="loginTablo">
                <tr>
                    <td class="UstBaslik">Kullanıcı Girişi</td>
                </tr>
                <tr>
                    <td class="Hucre">
                        <input type="text" id="txtKullaniciAdi" runat="server" class="form-control" placeholder="User name"/></td>
                </tr>
                <tr>
                    <td class="Hucre">
                        <input type="password" id="txtKullaniciSifre" runat="server" class="form-control" placeholder="Password" /></td>
                </tr>
                <tr>
                    <td class="Hucre">
                        <telerik:RadCaptcha ID="RadCaptcha1" runat="server" CaptchaTextBoxLabel="Lütfen Resmi Giriniz" EnableRefreshImage="True" CaptchaLinkButtonText="Yenile"  ValidationGroup="Group">
                            <CaptchaImage  TextChars="Numbers" TextColor="#000000" BackgroundColor="#9eb2c5"></CaptchaImage>                             
                            <TextBoxDecoration CssClass="form-control" />                                      
                        </telerik:RadCaptcha>
                    </td>
                </tr>
                <tr>
                    <td class="Hucre">
                        <asp:HyperLink ID="lblYeniKayit" runat="server" NavigateUrl="~/KullaniciKayit.aspx">Üye Olmak İstiyorum</asp:HyperLink>
                    </td>
                </tr>
                <tr>
                    <td style="text-align:right;">
                        <asp:Button ID="btnGiris" runat="server" Text="Giriş"  CssClass="Girisbutton" OnClick="btnGiris_Click" ValidationGroup="Group" PostBackUrl="~/Default.aspx" />

                    </td>
                </tr>

            </table>
        </div>
        <div class="GirisPanelGolge">
        </div>


        <telerik:RadNotification ID="RadNotification1" runat="server" EnableRoundedCorners="true"
            EnableShadow="true" Text="Sample content" Title="Bilgilendirme" Width="300" Height="100">
        </telerik:RadNotification>


        <script src="/LCSK/assets/js/jquery-2.1.1.min.js" type="text/javascript"></script>
        <script src="/LCSK/assets/js/jquery.signalR-2.1.1.min.js" type="text/javascript"></script>
        <script src="/signalr/hubs" type="text/javascript"></script>
        <script src="/LCSK/chat.js" type="text/javascript"></script>

    </form>
</body>
</html>
