<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="DosyaYoneticisi.aspx.cs" Inherits="GaziProje2014.Forms.DosyaYoneticisi" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="DosyaYoneticisi">
        <telerik:RadFileExplorer ID="FileExplorer1" runat="server" Width="100%" Height="640px" EnableOpenFile="true">
            <Configuration MaxUploadFileSize="80000000" />
        </telerik:RadFileExplorer>
    </div>

</asp:Content>
