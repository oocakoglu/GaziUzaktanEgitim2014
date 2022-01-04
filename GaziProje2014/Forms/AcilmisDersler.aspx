<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="AcilmisDersler.aspx.cs" Inherits="GaziProje2014.Forms.AcilmisDersler" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server" >      
    <div class="contentUst40">
        <table class="tdTablo">
            <tr>
                <td class="tdCellBaslik">Ders Adı :</td>
                <td class="tdCellIcerik"><telerik:RadTextBox ID="txtDersAdi" runat="server"></telerik:RadTextBox></td>
                <td class="tdCellBaslik">Öğretmen Adı :</td>
                <td class="tdCellIcerik"><telerik:RadTextBox ID="txtOgretmenAdi" runat="server"></telerik:RadTextBox></td>       
                <td class="tdCellBaslik">  
                <telerik:RadButton ID="btnSorgula" runat="server" Text="Sorgula" OnClick="btnSorgula_Click">
                </telerik:RadButton> 
                </td>                                                           
            </tr>
        </table>
    </div>
    <div class="contentUst40Golge">
    </div>

    <div class="contentOrta40x40">       
        <telerik:RadGrid ID="grdOgrenciDersSecim" runat="server" CellSpacing="-1"  GridLines="Both">
            <ClientSettings EnableRowHoverStyle="true">
                <Selecting AllowRowSelect="True" />
            </ClientSettings>
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="OgretmenDersId, OgretmenId, DersId">
                <Columns>

                    <telerik:GridBoundColumn DataField="DersAdi"  HeaderText="DersAdi" SortExpression="DersAdi" UniqueName="DersAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="DersAciklama"  HeaderText="DersAciklama"  UniqueName="DersAciklama">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="DersiVeren"  HeaderText="Dersi Veren Kişi"  UniqueName="DersiVeren">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="DersAlanOgrenci" DataType="System.Int32" HeaderText="Dersi Alan Öğrenci Sayısı"  UniqueName="DersiAlanOgrenci">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>
                    
                </Columns>
            </MasterTableView>
        </telerik:RadGrid>    
    </div>   
         
    <div class="contentAlt30">
        <telerik:RadButton Width="150px" ID="btnDersAlanOgrenci" runat="server" Text="Dersi Alan Öğrenciler" OnClick="btnDersAlanOgrenci_Click"></telerik:RadButton>     
        <telerik:RadButton Width="150px" ID="btnDersIcerikGor" runat="server" Text="Dersin İçeriğini Gör" OnClick="btnDersIcerikGor_Click"></telerik:RadButton>     
    </div>
    <div class="contentAlt30Golge"> 
    </div>

    </telerik:RadAjaxPanel>

</asp:Content>
