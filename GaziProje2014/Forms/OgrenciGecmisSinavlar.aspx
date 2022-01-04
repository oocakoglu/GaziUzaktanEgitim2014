<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="OgrenciGecmisSinavlar.aspx.cs" Inherits="GaziProje2014.Forms.OgrenciGecmisSinavlar" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server" >      
    <div class="contentUst40">
        <table class="tdTablo">
            <tr>
                <td class="tdCellBaslik">Sınav Adı :</td>
                <td class="tdCellIcerik"><telerik:RadTextBox ID="txtSinavAdi" runat="server"></telerik:RadTextBox></td>
                <td class="tdCellBaslik">Ders Adı :</td>
                <td class="tdCellIcerik"><telerik:RadTextBox ID="txtDersAdi" runat="server"></telerik:RadTextBox></td>       
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
        <telerik:RadGrid ID="grdSinavlar" runat="server" CellSpacing="-1"  GridLines="Both">
            <ClientSettings EnableRowHoverStyle="true">
                <Selecting AllowRowSelect="True" />
            </ClientSettings>
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="SinavId">
                <Columns>
                      
                    <telerik:GridBoundColumn DataField="SinavId" DataType="System.Int32" UniqueName="SinavId" Display="false">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="BitisTarihi"  HeaderText="Sınav Son Tarih" SortExpression="BitisTarihi" UniqueName="BitisTarihi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="BitisZamani"  HeaderText="Girilme Tarihi" SortExpression="BitisZamani" UniqueName="BitisZamani">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="SinavAdi"  HeaderText="Sınav Adı" SortExpression="SinavAdi" UniqueName="SinavAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridTemplateColumn SortExpression="DersAdi" UniqueName="TemplateClmnYonetici" HeaderText="Ders Adi">
                        <ItemTemplate>                                  
                            <asp:Label ID="lblYoneticiOnayi" runat="server" Text='<%# Eval("DersAdi") ==null ? "Genel Sınav" : Eval("DersAdi") %>'></asp:Label>
                        </ItemTemplate>
                    </telerik:GridTemplateColumn>
                    
                    <telerik:GridBoundColumn DataField="SoruSayisi"  HeaderText="Toplam S." SortExpression="SoruSayisi" UniqueName="SoruSayisi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                        <HeaderStyle Width="70px"/>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="DogruCevap"  HeaderText="Dogru S." SortExpression="DogruCevap" UniqueName="DogruCevap">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                        <HeaderStyle Width="70px"/>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="YanlisCevap"  HeaderText="Yanlis S." SortExpression="YanlisCevap" UniqueName="YanlisCevap">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                        <HeaderStyle Width="70px"/>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="BosCevap"  HeaderText="Bos S." SortExpression="BosCevap" UniqueName="BosCevap">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                        <HeaderStyle Width="70px"/>
                    </telerik:GridBoundColumn>

                </Columns>
            </MasterTableView>
        </telerik:RadGrid>    
    </div>   
    </telerik:RadAjaxPanel>
         
    <div class="contentAlt30">
        <telerik:RadButton Width="100px" ID="btnSinavaGir" runat="server" Text="Sınav Ekle"></telerik:RadButton>     
    </div>
    <div class="contentAlt30Golge"> 
    </div>

    


</asp:Content>
