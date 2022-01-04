<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="SoruDetay.aspx.cs" Inherits="GaziProje2014.Forms.SoruDetay" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <style>
        .legendForm1 {
            padding: 4px;
            position: absolute;
            left: 10px;
            top: -11px;
            background-color: #2DABC1;
            color: white;
            -webkit-border-radius: 4px;
            -moz-border-radius: 4px;
            border-radius: 4px;
            box-shadow: 2px 2px 4px #888;
            -moz-box-shadow: 2px 2px 4px #888;
            -webkit-box-shadow: 2px 2px 4px #888;
            text-shadow: 1px 1px 1px #333;
            
        }

        .fieldsetForm1 {
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
            width:600px;
        }
        .DisDiv{
            padding:30px;
        }
    </style>

    <asp:TextBox ID="txtSoruSira" runat="server" Visible="false"></asp:TextBox>
    <asp:TextBox ID="txtResimYol" runat="server" Enabled="false" Visible="false" ></asp:TextBox>

    <div class="DisDiv">
        <fieldset class="fieldsetForm1">
            <legend class="legendForm1">Soru Giriniz &nbsp;
            </legend>

            <table>
                <tr>
                    <td style="width:110px;"></td>
                    <td style="width:180px;"></td>  
                    <td style="width:110px;"></td>                  
                    <td style="width:180px;"></td>                    
                </tr>

                <tr>
                    <td style="width:110px;">Sorunun Dersi :</td>
                    <td colspan="3">
                        <telerik:RadComboBox ID="rdDersler" runat="server" Width="300px"></telerik:RadComboBox>
                    </td>                  
                </tr>

                <tr>
                    <td>Soru Konu</td>
                    <td>
                        <asp:TextBox ID="txtDersKonu" runat="server"  Width="300px"></asp:TextBox>                        
                    </td>
                    <td colspan="2">
                        
                    </td>
                
                </tr>
                <tr>
                    <td>Soru Resim</td>
                    <td>
                        <asp:FileUpload ID="flupldResim" runat="server" Width="182px" />
                    </td>
                    <td>
                        <telerik:RadButton ID="btnResimYukle" runat="server" Text="Resmi Yükle" OnClick="btnResimYukle_Click"></telerik:RadButton>
                    </td>
                    <td>
                        <telerik:RadButton ID="btnResimSil" runat="server" Text="Resmi Sil" OnClick="btnResimSil_Click"></telerik:RadButton>
                    </td>
                </tr>
                <tr>
                    <td></td>
                    <td colspan="3">
                        <asp:Image ID="imgSoruResim" runat="server" ImageUrl="" />
                    </td>
                </tr>
                <tr>
                    <td colspan="4">Soru:
                    </td>
                </tr>
                <tr>
                    <td colspan="4">
                        <telerik:RadTextBox ID="txtSoruIcerik" runat="server" Height="69px" TextMode="MultiLine" Width="100%"></telerik:RadTextBox>
                    </td>
                </tr>
                <tr>
                    <td colspan="4">


                        <table style="width: 100%">
                            <tr>
                                <td style="width:74px;">
                                    <asp:RadioButton ID="rdCvp1" runat="server"  Text="Cevap 1:" GroupName="groupDogruCevap" Font-Size="X-Large" />
                                </td>
                                <td>
                                    <telerik:RadTextBox ID="txtCvp1" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text=""></telerik:RadTextBox>
                                </td>
                            </tr>

                            <tr>
                                <td>
                                    <asp:RadioButton ID="rdCvp2" runat="server"  Text="Cevap 2:" GroupName="groupDogruCevap" Font-Size="X-Large" />
                                </td>
                                <td>
                                    <telerik:RadTextBox ID="txtCvp2" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text=""></telerik:RadTextBox>
                                </td>
                            </tr>

                            <tr>
                                <td>
                                    <asp:RadioButton ID="rdCvp3" runat="server"  Text="Cevap 3:" GroupName="groupDogruCevap" Font-Size="Large" />
                                </td>
                                <td>
                                    <telerik:RadTextBox ID="txtCvp3" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text=""></telerik:RadTextBox>
                                </td>
                            </tr>

                            <tr>
                                <td>
                                    <asp:RadioButton ID="rdCvp4" runat="server"  Text="Cevap 4:" GroupName="groupDogruCevap" Font-Size="Large" />
                                </td>
                                <td>
                                    <telerik:RadTextBox ID="txtCvp4" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text=""></telerik:RadTextBox>
                                </td>
                            </tr>

                            <tr>
                                <td>
                                    <asp:RadioButton ID="rdCvp5" runat="server"  Text="Cevap 5:" GroupName="groupDogruCevap" Font-Size="Large" />
                                </td>
                                <td>
                                    <telerik:RadTextBox ID="txtCvp5" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text=""></telerik:RadTextBox>
                                </td>
                            </tr>
                        </table>

                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Button ID="btnGuncelle" runat="server" Text="Güncelle" Width="70px" OnClick="btnGuncelle_Click"></asp:Button>
                    </td>
                    <td>
                        <asp:Button ID="btnIptal" runat="server" Text="Vazgeç" CausesValidation="false" Width="70px"></asp:Button>
                    </td>
                    <td></td>
                    <td></td>
                </tr>
            </table>

        </fieldset>
    </div>

    <telerik:RadNotification ID="RadNotification1" runat="server" EnableRoundedCorners="true"
        EnableShadow="true" Text="Sample content" Title="Bilgilendirme" Width="300" Height="100">
    </telerik:RadNotification>

</asp:Content>
