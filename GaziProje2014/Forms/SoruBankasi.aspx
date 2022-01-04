<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="SoruBankasi.aspx.cs" Inherits="GaziProje2014.Forms.SoruBankasi" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server" >      
    <div class="contentUst40">
        <table class="tdTablo">
            <tr>
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

        <telerik:RadGrid ID="grdSoruBankasi" runat="server" AllowMultiRowSelection="True">
            <ExportSettings>
                <Pdf PageWidth="">
                </Pdf>
            </ExportSettings>
            <ClientSettings  EnableRowHoverStyle="true">
                <Selecting AllowRowSelect="True"></Selecting>                     
            </ClientSettings>
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="OgretmenDersId" Height="100%" TableLayout="Fixed">
                <Columns>
                    <telerik:GridBoundColumn DataField="OgretmenDersId" DataType="System.Int32"  HeaderText="OgretmenDersId" ReadOnly="True" UniqueName="OgretmenDersId">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="DersAdi"  HeaderText="Ders Adı" UniqueName="DersAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                        <HeaderStyle Width="360px"/>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="Ogretmen" HeaderText="Ogretmen" UniqueName="Ogretmen">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="SinavSayisi" DataType="System.Int32" HeaderText="SinavSayisi" UniqueName="SinavSayisi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="SoruSayisi" DataType="System.Int32" HeaderText="SoruSayisi" UniqueName="SoruSayisi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="SinavdaKullanilanSoru" DataType="System.Int32" HeaderText="SinavdaKullanilanSoru" UniqueName="SinavdaKullanilanSoru">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                </Columns>
            </MasterTableView>
        </telerik:RadGrid>

    </div>   
       
    <div class="contentAlt30">
        <telerik:RadButton Width="150px" ID="btnYeniSoru" runat="server" Text="Derse Soru Ekle" OnClick="btnYeniSoru_Click"></telerik:RadButton>     
        <telerik:RadButton Width="150px" ID="btnDersSorulari" runat="server" Text="Dersin Sorularını Gör" OnClick="btnDersSorulari_Click"></telerik:RadButton>     
<%--         <telerik:RadButton Width="150px" ID="RadButton1" runat="server" Text="Derse Soru Ekle" OnClick="btnDersleriOnayla_Click"></telerik:RadButton>     
        <telerik:RadButton Width="150px" ID="RadButton2" runat="server" Text="Dersin Sorularını Gör" OnClick="btnDersleriSil_Click"></telerik:RadButton>  --%> 
    </div>
    <div class="contentAlt30Golge"> 
    </div>

    </telerik:RadAjaxPanel>  
    



</asp:Content>
