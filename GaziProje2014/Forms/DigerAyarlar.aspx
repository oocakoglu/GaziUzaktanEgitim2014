<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="DigerAyarlar.aspx.cs" Inherits="GaziProje2014.Forms.DigerAyarlar" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
   
     <table style="width:100%;">
         <tr>             
             <td>
                 <asp:Button ID="btnSeo" runat="server" Text="SiteMap Getir" OnClick="btnSeo_Click" />
                 <asp:Button ID="btnKaydet" runat="server" Text="Kaydet" OnClick="btnKaydet_Click" />
             </td>
         </tr>
         <tr>             
             <td>
                  <asp:TextBox ID="btnTxtSiteMap" runat="server" TextMode="MultiLine" Width="98%" Height="500px" ValidateRequestMode="Disabled"></asp:TextBox>
             </td>
         </tr>
    </table>

</asp:Content>
