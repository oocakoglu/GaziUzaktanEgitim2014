<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="IcerikDisaYayin.aspx.cs" Inherits="GaziProje2014.Forms.IcerikDisaYayin" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <style>
    .SolIcerikBasliklar 
    {
        position: absolute;
        top: 0px;
        left: 0px;
        width:250px;
        bottom: 30px;      
        overflow: scroll;
        overflow-x:hidden;   
    }

    .IcerikDetay
    {
        position: absolute;
        top: 0px;
        left: 250px;
        right:0px;
        bottom: 30px;      
        overflow: scroll;
        overflow-x:hidden;  
          
    }


    </style>

    <div class="SolIcerikBasliklar">
       <telerik:RadGrid ID="grdIcerikBasliklar" runat="server" CellSpacing="-1"  GridLines="Both" AllowMultiRowSelection="false" OnSelectedIndexChanged="grdIcerikBasliklar_SelectedIndexChanged">
            <ClientSettings EnableRowHoverStyle="true" EnablePostBackOnRowClick="true">
                <Selecting AllowRowSelect="True" />
            </ClientSettings>
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="IcerikId">
                <Columns>

                    <telerik:GridBoundColumn DataField="IcerikId" DataType="System.Int32" UniqueName="IcerikId" Display="false">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="DersAdi" HeaderText="DersAdi"   UniqueName="DersAciklama">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="IcerikAdi"  HeaderText="IcerikAdi"  UniqueName="IcerikAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                </Columns>
            </MasterTableView>
        </telerik:RadGrid>    
    </div>
    <div class="IcerikDetay">
        <table>
            <tr>
                <td colspan="2">
                    <asp:CheckBox ID="chkPublic" runat="server" Text="Dışarıya Açık" />
                </td>
                <td rowspan="5" colspan="2">
                    <asp:Image ID="Imgthumbnail" runat="server" Height="90px" Width="160px" />
                </td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="Label1" runat="server" Text="Başlık"></asp:Label>
                </td>
                <td>
                    <telerik:RadTextBox ID="txtBaslik" runat="server" Width="300"></telerik:RadTextBox>
                </td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="Label2" runat="server" Text="Url Adı:"></asp:Label>
                </td>
                <td>
                    <telerik:RadTextBox ID="txtUrlName" runat="server" Width="300"></telerik:RadTextBox>
                </td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="Label6" runat="server" Text="İçerik Tipi:"></asp:Label>
                </td>
                <td>
                    <telerik:RadComboBox ID="cbIcerikTipi" runat="server" Width="300" Enabled="false">
                        <Items>
                            <telerik:RadComboBoxItem runat="server" Text="Text İçerik" Value="1" />
                            <telerik:RadComboBoxItem runat="server" Text="Dosyadan Seçim (Video, Pdf)" Value="2" />
                            <telerik:RadComboBoxItem runat="server" Text="Bir Kaynaktan Embed" Value="3" />
                        </Items>
                    </telerik:RadComboBox>
          
                </td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="Label4" runat="server" Text="İçerik Url:"></asp:Label>
                </td>
                <td>
                    <telerik:RadTextBox ID="txtIcerikUrl" runat="server" Width="300"></telerik:RadTextBox>
                </td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="Label5" runat="server" Text="Video Saniye:"></asp:Label>
                </td>
                <td>
                   <telerik:RadTextBox ID="txtVideoSaniye" runat="server" Width="300"></telerik:RadTextBox>
                </td>
                <td>
                    <asp:FileUpload ID="FileUpload1" runat="server" Width="182px" />                                              
                </td>
                <td>
                    <asp:Button ID="btnYukle" runat="server" Text="Yükle" Width="67px" Height="22px" OnClick="btnYukle_Click"/> 
                </td>
            </tr>

            <tr>
                <td style="vertical-align:top;">
                    <asp:Label ID="Label3" runat="server" Text="Açıklama:"></asp:Label>
                </td>
                <td colspan="3">
                    <telerik:RadTextBox ID="txtUrlAciklama" runat="server" Width="100%" Height="80" TextMode="MultiLine" ></telerik:RadTextBox>
                </td>
            </tr>
            <tr>
                <td>
                    <asp:Label ID="Label7" runat="server" Text="SiteMap:"></asp:Label>
                </td>
                <td>
                    <telerik:RadTextBox ID="txtSiteMap" runat="server" Width="100%" Height="180" TextMode="MultiLine" ></telerik:RadTextBox>
                </td>
            </tr>




        </table>
        <asp:HiddenField ID="hdnIcerikId" runat="server" />
        <asp:HiddenField ID="hdnResimUrl" runat="server" />
    </div>

    <div class="contentAlt30">
        <telerik:RadButton Width="150px" ID="btnKaydet" runat="server" Text="Kaydet" OnClick="btnKaydet_Click"></telerik:RadButton>  
        <telerik:RadButton Width="150px" ID="btnSiteMap" runat="server" Text="SitemMap" OnClick="btnSiteMap_Click"></telerik:RadButton>    
    </div>
    <div class="contentAlt30Golge"> 
    </div>

</asp:Content>
