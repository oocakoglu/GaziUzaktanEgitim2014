<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="OgrenciDersleri.aspx.cs" Inherits="GaziProje2014.Forms.OgrenciDersleri" %>
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
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="OgrenciDersId, OgretmenDersId, UstOnay">
                <Columns>

                    <telerik:GridTemplateColumn UniqueName="chkTemplateColumn" Reorderable="False" Groupable="False">
                        <ItemTemplate>
                            <asp:CheckBox ID="chkOgrenciOnay"  runat="server" AutoPostBack="False" Visible='<%# !Convert.ToBoolean(Eval("UstOnay"))%>'></asp:CheckBox>
                        </ItemTemplate>
                        <HeaderStyle Width="70px"/>
                    </telerik:GridTemplateColumn>

                    <telerik:GridBoundColumn DataField="OgrenciDersId" DataType="System.Int32" UniqueName="OgrenciDersId" Display="false">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="OgretmenDersId" DataType="System.Int32"  UniqueName="OgretmenDersId" Display="False">
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
                    
                   <%--                
                    <telerik:GridTemplateColumn SortExpression="Öğrenci Onay" UniqueName="TemplateClmnOgrenci" HeaderText="Öğrenci Onayı">
                        <ItemTemplate>                                  
                            <asp:Label ID="lblOgretmenOnayi" runat="server" Text='<%# Convert.ToBoolean(Eval("OgrenciOnayi")) == true ? "Onayladınız" : "Onaylanmadı" %>'></asp:Label>
                        </ItemTemplate>
                    </telerik:GridTemplateColumn>
                    --%>

                    <telerik:GridTemplateColumn SortExpression="YoneticiOnay" UniqueName="TemplateClmnYonetici" HeaderText="Yönetici Onayı">
                        <ItemTemplate>                                  
                            <asp:Label ID="lblYoneticiOnayi" runat="server" Text='<%# Convert.ToBoolean(Eval("UstOnay")) == true ? "Yönetici Tarafından Onaylandı" : "Henüz Onaylanmadı" %>'></asp:Label>
                        </ItemTemplate>
                    </telerik:GridTemplateColumn>

                </Columns>
            </MasterTableView>
        </telerik:RadGrid>    
    </div>   
    </telerik:RadAjaxPanel>
         
    <div class="contentAlt30">
        <telerik:RadButton Width="150px" ID="btnDersleriOnayla" runat="server" Text="Dersleri Onayla" OnClick="btnDersleriOnayla_Click" Visible="false"></telerik:RadButton>     
        <telerik:RadButton Width="150px" ID="btnDersleriSil" runat="server" Text="Dersleri Sil" OnClick="btnDersleriSil_Click" CssClass="Buttons"></telerik:RadButton>     
        <telerik:RadButton Width="150px" ID="btnDersIcerik" runat="server" Text="Konuları Göster" OnClick="btnDersIcerik_Click"></telerik:RadButton> 
    </div>
    <div class="contentAlt30Golge"> 
    </div>

    
    <telerik:RadNotification ID="RadNotification1" runat="server" EnableRoundedCorners="true"
        EnableShadow="true" Text="Sample content" Title="Bilgilendirme" Width="300" Height="100">
    </telerik:RadNotification>

</asp:Content>
