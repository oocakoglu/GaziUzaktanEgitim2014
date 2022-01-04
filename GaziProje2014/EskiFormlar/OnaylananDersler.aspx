<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="OnaylananDersler.aspx.cs" Inherits="GaziProje2014.Forms.OnaylananDersler" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <style>  
        .DuyuruListeUst{
            position: absolute;
            top: 0px;
            left: 0px;
            right: 0px;
            height:40px;
        }   
        .DuyuruListeOrta {
            position: absolute;
            top: 40px;
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
        .tdCellIcerik
        {
            width:100px;
        }  
        .tdTablo
        {
            padding-top:10px;
            padding-left:10px;
        }   
    </style>  
    <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server" >      
    <div class="DuyuruListeUst">
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

    <div class="DuyuruListeOrta">       
        <telerik:RadGrid ID="grdOnayBekleyenDersler" runat="server" CellSpacing="-1"  GridLines="Both">
            <ClientSettings>
                <Selecting AllowRowSelect="True" />
                <Resizing AllowColumnResize="True" AllowResizeToFit="true" />
            </ClientSettings>
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="OgretmenDersId">
                <Columns>

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
    </telerik:RadAjaxPanel>
    <div class="DuyuruListeAlt">
        <telerik:RadButton Width="150px" ID="btnSecilenleriOnayla" runat="server" Text="Dersi Alan Öğrenciler"></telerik:RadButton>      
        <telerik:RadButton Width="150px" ID="btnSecilenleriSil" runat="server" Text="Ders Takvimi" OnClick="btnSecilenleriSil_Click"></telerik:RadButton>  
    </div>
    


</asp:Content>
