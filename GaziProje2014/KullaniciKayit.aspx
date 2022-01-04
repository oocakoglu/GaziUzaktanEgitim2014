<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="KullaniciKayit.aspx.cs" Inherits="GaziProje2014.Pages.KullaniciKayit" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <style type="text/css">
         body
        {
          text-align: center;
        } 
       
         .centered
        {
            width:1100px;
            height:400px; 
            /*margin-left: auto;
            margin-right: auto;*/
            text-align: left;
            position: absolute;
            top:0;
            bottom: 0;
            left: 0;
            right: 0;
            margin: auto;     
        } 

            /*width: 150px;
            height: 24px;*/

        .form-control {
            display: block;            
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

        .RadPicker .RadInput .riTextBox 
        { 
            height:28px;
            display: block; 
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

        div.CustomCssClass .rcbInputCell INPUT.rcbInput
        {    
            display: block; 
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

        .BaslikHucre
        {
            width:200px;
        }


    </style>
</head>
<body>
    <form id="form1" runat="server">
        
        <telerik:RadScriptManager ID="RadScriptManager1" Runat="server">
        </telerik:RadScriptManager>


<div class="centered">
      <table>
          
          <tr>              
              <td class="BaslikHucre">Kullanıcı Tipi :</td>
              <td>                 
                   <asp:DropDownList ID="cbKullaniciTipleri" runat="server" CssClass="form-control"></asp:DropDownList>
                   
              </td>

              <td></td>
              <td  class="BaslikHucre"></td>               
              <td rowspan="11" style="width:450px; text-align:right;">             
                 
                        <asp:Image ID="Image1" runat="server" ImageUrl="~/Style/Images/SolResim2.png" />                       
                                
              </td>
          </tr>
          <tr>
              <td>Kullanıcı Adınız :</td>
              <td>                 
                   <asp:TextBox ID="txtKullaniciAdi" runat="server" CssClass="form-control"></asp:TextBox>
              </td>

              <td>Şifreniz :</td>
              <td>                 
                   <asp:TextBox ID="txtSifre" runat="server" TextMode="Password" CssClass="form-control"></asp:TextBox>
              </td>
          </tr>

          <tr>
              <td class="BaslikHucre">Adınız :</td>
              <td>                 
                   <asp:TextBox ID="txtAdi" runat="server" CssClass="form-control"></asp:TextBox>
              </td>

              <td class="BaslikHucre">Soyadınız :</td>
              <td>                 
                   <asp:TextBox ID="txtSoyadi" runat="server" CssClass="form-control"></asp:TextBox>
              </td>
          </tr>

          <tr>
              <td>Doğum Tarihiniz :</td>
              <td>        
                  <telerik:RadDatePicker ID="dteDogumTarihi" runat="server" Culture="tr-TR" CssClass="CustomCssClass"></telerik:RadDatePicker>         
              </td>

              <td>Cinsiyetiniz :</td>
              <td>                 
                   <asp:DropDownList ID="cbCinsiyet" runat="server" Width="150px" CssClass="form-control">
                       <asp:ListItem Value="1">Erkek</asp:ListItem>
                       <asp:ListItem Value="0">Bayan</asp:ListItem>
                   </asp:DropDownList>
              </td>
          </tr>

          <tr>
              <td>Cep Telefonunuz :</td>
              <td>                 
                   <asp:TextBox ID="txtCepTel" runat="server" CssClass="form-control"></asp:TextBox>
              </td>

              <td>Ev Telefonunuz :</td>
              <td>                 
                   <asp:TextBox ID="txtEvTel" runat="server" CssClass="form-control"></asp:TextBox>
              </td>
          </tr>

          <tr>
              <td>E-Mail Adresiniz :</td>
              <td>                 
                   <asp:TextBox ID="txtemail" runat="server"  CssClass="form-control"></asp:TextBox>
              </td>

              <td></td>
              <td></td>             
          </tr>

           
          <tr>
              <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server" >
              <td>Yaşadığınız Şehir :</td>
              <td>                 
                    <telerik:RadComboBox ID="cbIlAdi" runat="server" OnSelectedIndexChanged="cbIlAdi_SelectedIndexChanged"
                        AutoPostBack="True"  CssClass="CustomCssClass" >
                    </telerik:RadComboBox>
              </td>

              <td>Yaşadığınız İlçe :</td>
              <td>                 
                    <telerik:RadComboBox ID="cbIlceAdi" runat="server"  CssClass="CustomCssClass" >
                    </telerik:RadComboBox>
              </td>
              </telerik:RadAjaxPanel>
          </tr>


          <tr>
              <td rowspan="2">Yaşadığınız Şehir :</td>
              <td rowspan="2" colspan="3" >                 
                   <asp:TextBox ID="txtAdres" runat="server" Height="38px" TextMode="MultiLine" Width="416px" CssClass="form-control"></asp:TextBox>
              </td>
          </tr>
          
          <tr>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
          </tr>

          <tr>
              <td></td>
              <td colspan="3">
                <telerik:RadCaptcha ID="RadCaptcha1" Runat="server" ValidationGroup="kayitFormu">
                     <TextBoxDecoration CssClass="form-control" /> 
                </telerik:RadCaptcha>
              </td>
          </tr>
          <tr>
              <td><asp:Button ID="btnKaydet" runat="server" Text="Kaydet" OnClick="btnKaydet_Click" ValidationGroup="kayitFormu" CssClass="button"/></td>
              <td><asp:Button ID="btnVazgec" runat="server" Text="Vazgeç" OnClick="btnVazgec_Click" /></td>
              <td><asp:Button ID="btnAnaSayfa" runat="server" Text="Siteye Git" OnClick="btnAnaSayfa_Click"/></td>
              <td></td>
              <td></td>
          </tr>

      </table>

</div>

        <telerik:RadNotification ID="RadNotification1" runat="server" EnableRoundedCorners="true"
            EnableShadow="true" Text="Sample content" Title="Bilgilendirme" Width="300" Height="100">
        </telerik:RadNotification>

    </form>
</body>
</html>
