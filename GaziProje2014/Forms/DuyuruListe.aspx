<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="DuyuruListe.aspx.cs" Inherits="GaziProje2014.Forms.DuyuruListe" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
  
    <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server" >      
    <div class="contentUst70">
        <table class="tdTablo">
            <tr>
                <td class="tdCellIcerik">Tarih Aralığı :</td>
                <td class="tdCellIcerik"><telerik:RadDatePicker ID="dteBaslangicTarihi" runat="server"></telerik:RadDatePicker></td>
                <td class="tdCellIcerik"><telerik:RadDatePicker ID="dteBitisTarihi" runat="server"></telerik:RadDatePicker></td>
                <td class="tdCellIcerik"></td>                                                       
            </tr>
            <tr>
                <td class="tdCellIcerik">Duyuru Adı :</td>
                <td colspan="2"><telerik:RadTextBox ID="txtDuyuruAdi" runat="server" Width="298px"></telerik:RadTextBox></td> 
                <td class="tdCellIcerik">  
                <telerik:RadButton ID="btnDuyuruListeSorgula" runat="server" Text="Sorgula" OnClick="btnDuyuruListeSorgula_Click" >
                </telerik:RadButton> 
                </td>    
            </tr>
        </table>
    </div>
    <div class="contentUst70Golge">
    </div>

    <div class="contentOrta70x40">       
        <telerik:RadGrid ID="RadGrid1" runat="server" CellSpacing="-1"  GridLines="Both">
            <ClientSettings EnableRowHoverStyle="true">
                <Selecting AllowRowSelect="True" />
            </ClientSettings>
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="DuyuruId" >
                <Columns>

                    <telerik:GridBoundColumn DataField="DuyuruTarihi" DataType="System.DateTime" FilterControlAltText="Filter DuyuruTarihi column" HeaderText="DuyuruTarihi" SortExpression="DuyuruTarihi" UniqueName="DuyuruTarihi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="DuyuruAdi" FilterControlAltText="Filter DuyuruAdi column" HeaderText="DuyuruAdi" SortExpression="DuyuruAdi" UniqueName="DuyuruAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="Adi" FilterControlAltText="Filter Adi column" HeaderText="Ekleyen Adı" SortExpression="Adi" UniqueName="Adi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="Soyadi" FilterControlAltText="Filter Soyadi column" HeaderText="Ekleyen Soyadı" SortExpression="Soyadi" UniqueName="Soyadi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>


                    <telerik:GridBoundColumn DataField="DuyuruId" DataType="System.Int32" FilterControlAltText="Filter DuyuruId column" HeaderText="DuyuruId" ReadOnly="True" SortExpression="DuyuruId" UniqueName="DuyuruId" Display="false">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                </Columns>
            </MasterTableView>
        </telerik:RadGrid>     

    </div>
    </telerik:RadAjaxPanel>
    <div class="contentAlt30">
        <telerik:RadButton Width="100px" ID="btnYeniEkle" runat="server" Text="Yeni Ekle" OnClick="btnYeniEkle_Click"></telerik:RadButton>         
        <telerik:RadButton Width="100px" ID="btnDuzenle" runat="server" Text="Düzenle" OnClick="btnDuzenle_Click"></telerik:RadButton>         
        <telerik:RadButton Width="100px" ID="btnSil" runat="server" Text="Sil" OnClick="btnSil_Click"></telerik:RadButton>      
    </div>
    <div class="contentAlt30Golge"> 
    </div>

    <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" SelectCommand="SELECT [DuyuruId], [DuyuruAdi], [DuyuruIcerik], [DuyuruTarihi], [DuyuruKayitEdenId] FROM [Duyurular]"></asp:SqlDataSource>
 
</asp:Content>
