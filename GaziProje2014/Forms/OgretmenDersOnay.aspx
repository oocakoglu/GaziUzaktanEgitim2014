<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="OgretmenDersOnay.aspx.cs" Inherits="GaziProje2014.Forms.OgretmenDersOnay" %>
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
        <telerik:RadGrid ID="grdOnayBekleyenDersler" runat="server" CellSpacing="-1"  GridLines="Both">
            <ClientSettings EnableRowHoverStyle="true">
                <Selecting AllowRowSelect="True" />
            </ClientSettings>
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="OgretmenDersId">
                <Columns>

                    <telerik:GridTemplateColumn UniqueName="chkTemplateColumn" Reorderable="False" Groupable="False">
                        <ItemTemplate>
                            <asp:CheckBox ID="chkUstOnay"  runat="server" AutoPostBack="False"></asp:CheckBox>
                        </ItemTemplate>
                        <HeaderStyle Width="70px"/>
                    </telerik:GridTemplateColumn>

                    <telerik:GridBoundColumn DataField="OgretmenDersId" DataType="System.Int32" UniqueName="OgretmenDersId" Display="false">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="DersAdi" FilterControlAltText="Filter DersAdi column" HeaderText="DersAdi" SortExpression="DersAdi" UniqueName="DersAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="DersiVeren"  HeaderText="Dersi Veren Kişi" SortExpression="DersiVeren" UniqueName="DersiVeren">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="DersAciklama" FilterControlAltText="Filter DersAciklama column" HeaderText="DersAciklama" SortExpression="DersAciklama" UniqueName="DersAciklama">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                </Columns>
            </MasterTableView>
        </telerik:RadGrid>    
    </div>    
    <div class="contentAlt30">
        <telerik:RadButton Width="150px" ID="btnSecilenleriOnayla" runat="server" Text="Seçilen Dersleri Onayla" OnClick="btnSecilenleriOnayla_Click"></telerik:RadButton>      
        <telerik:RadButton Width="150px" ID="btnSecilenleriSil" runat="server" Text="Seçilen Dersleri Sil" OnClick="btnSecilenleriSil_Click"></telerik:RadButton>  
    </div>
    <div class="contentAlt30Golge"> 
    </div>
    </telerik:RadAjaxPanel>

</asp:Content>
