<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="DersIcerikGoruntule.aspx.cs" Inherits="GaziProje2014.Forms.DersIcerikGoruntule" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    
    <style>  
        .IcerikFrame {
            padding:5px;
            position: absolute;
            top: 0px;
            left: 0px;
            right: 0px;
            bottom: 40px;           
        }

        .IcerikContent{
            padding:5px;
            position: absolute;
            top: 0px;
            left: 0px;
            right: 0px;
            bottom: 40px;      
            overflow: scroll;
            overflow-x:hidden;  
        }

        .DuyuruListeAlt {
            height: 30px;
            padding:5px;      
            position: absolute;
            bottom: 0px;
            right: 0px;
            left: 0px;
        } 

    </style> 


   <div runat="server" class="IcerikFrame" id="pnlIcerikFrame">
   </div>

   <div runat="server" class="IcerikContent" id="pnlIcerikContent">      
   </div>

    <div class="contentAlt30">
        <telerik:RadButton Width="70px" ID="RadButton3" runat="server" Text="Geri" OnClick="btnGeri_Click"  >
             <Icon PrimaryIconUrl="~/Style/btnBack.png"/>
        </telerik:RadButton>  
    </div>
    <div class="contentAlt30Golge"> 
    </div>

     
</asp:Content>
