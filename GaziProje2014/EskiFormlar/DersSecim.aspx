<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="DersSecim.aspx.cs" Inherits="GaziProje2014.Forms.DersSecim" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

   
    <style>
        .DersSecimOrta {
            position: absolute;
            top: 36px;
            left: 0px;
            right: 0px;
            bottom: 36px;
            overflow: scroll;
            overflow-x:hidden;
        }

        .DersSecimAlt {   
            position: absolute;
            height: 30px;
            padding-left: 5px;
            padding-top:5px;
            bottom: 0px;
            right: 0px;
            left: 0px;
            /*background-color:red;*/
        }
    </style>



    <telerik:RadTabStrip runat="server"   ID="RadTabStrip1" AutoPostBack="true"   MultiPageID="RadMultiPage1" SelectedIndex="0"> 
        <Tabs>
            <telerik:RadTab Text="Tüm Dersler" Width="200px" PageViewID="RadPageView1"></telerik:RadTab>
            <telerik:RadTab Text="Seçilen Dersler" Width="200px" PageViewID="RadPageView2"></telerik:RadTab>
        </Tabs>
    </telerik:RadTabStrip>  
    
    <telerik:RadMultiPage runat="server" ID="RadMultiPage1" SelectedIndex="0">
        <telerik:RadPageView runat="server" ID="RadPageView1">
            <div class="DersSecimOrta">
                <telerik:RadGrid ID="grdTumDersler" runat="server" >
                    <ClientSettings>
                        <Selecting AllowRowSelect="True"></Selecting>
                        <ClientEvents OnGridCreated="gridCreated" />
                    </ClientSettings>

                    <MasterTableView AutoGenerateColumns="False" DataKeyNames="DersId" Height="100%" TableLayout="Fixed">
                        <Columns>
                            <telerik:GridTemplateColumn UniqueName="TemplateColumn" Reorderable="False" Groupable="False">
                                <ItemTemplate>
                                    <asp:CheckBox ID="CheckBox1"  runat="server" AutoPostBack="False"></asp:CheckBox>
                                </ItemTemplate>
                                <HeaderStyle Width="70px"/>
                            </telerik:GridTemplateColumn>

                            <telerik:GridBoundColumn DataField="DersId" DataType="System.Int32" FilterControlAltText="Filter DersId column" HeaderText="DersId" ReadOnly="True" SortExpression="DersId" UniqueName="DersId" Display="False">
                            </telerik:GridBoundColumn>

                            <telerik:GridBoundColumn DataField="DersAdi" FilterControlAltText="Filter DersAdi column" HeaderText="DersAdi" SortExpression="DersAdi" UniqueName="DersAdi">
                                <ColumnValidationSettings>
                                    <ModelErrorMessage Text="" />
                                </ColumnValidationSettings>
                                <HeaderStyle Width="360px"/>
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
            <div class="DersSecimAlt">
                <telerik:RadButton Width="100px" ID="btnDersEkle" runat="server" Text="Seçilenleri Ekle" OnClick="btnDersEkle_Click"></telerik:RadButton>
            </div>
        </telerik:RadPageView>
        <telerik:RadPageView runat="server" Height="100%" ID="RadPageView2">
            <div  class="DersSecimOrta">
                <telerik:RadGrid ID="grdSecilenDersler" runat="server" AllowMultiRowSelection="True">
                    <ExportSettings>
                        <Pdf PageWidth="">
                        </Pdf>
                    </ExportSettings>
                    <ClientSettings>
                        <Selecting AllowRowSelect="True"></Selecting>
                        <ClientEvents OnGridCreated="gridCreated" />
                    </ClientSettings>

                    <MasterTableView AutoGenerateColumns="False" DataKeyNames="OgretmenDersId" Height="100%" TableLayout="Fixed">
                        <Columns>
                            <telerik:GridTemplateColumn UniqueName="secilenTemplateColumn" Reorderable="False" Groupable="False">
                                <ItemTemplate>
                                    <%--<asp:CheckBox ID="CheckBox2" onclick="CheckItem(this);" runat="server" AutoPostBack="False"></asp:CheckBox>--%>
                                    <asp:CheckBox ID="CheckBox2" runat="server" AutoPostBack="False" Visible='<%# !Convert.ToBoolean(Eval("UstOnay"))%>'></asp:CheckBox>
                                </ItemTemplate>
                                <HeaderStyle Width="70px"/>
                            </telerik:GridTemplateColumn>
                            
                            <telerik:GridBoundColumn DataField="OgretmenDersId" DataType="System.Int32"  HeaderText="Id" ReadOnly="True" SortExpression="OgretmenDersId" UniqueName="OgretmenDersId" Display="False">
                                <ColumnValidationSettings>
                                    <ModelErrorMessage Text="" />
                                </ColumnValidationSettings>
                            </telerik:GridBoundColumn>

                            <telerik:GridBoundColumn DataField="DersAdi"  HeaderText="Ders Adı" SortExpression="DersAdi" UniqueName="secilenDersAdi">
                                <ColumnValidationSettings>
                                    <ModelErrorMessage Text="" />
                                </ColumnValidationSettings>
                                <HeaderStyle Width="360px"/>
                            </telerik:GridBoundColumn>

                            <telerik:GridBoundColumn DataField="DersAciklama" HeaderText="Ders Açıklama" SortExpression="DersAciklama" UniqueName="secilenDersAciklama">
                                <ColumnValidationSettings>
                                    <ModelErrorMessage Text="" />
                                </ColumnValidationSettings>
                            </telerik:GridBoundColumn>

                            <telerik:GridTemplateColumn SortExpression="OgretmenOnay" UniqueName="TemplateClmnOgretmen" HeaderText="Öğretmen Onayı">
                                <ItemTemplate>                                  
                                    <asp:Label ID="lblOgretmenOnayi" runat="server" Text='<%# Convert.ToBoolean(Eval("OgretmenOnayi")) == true ? "Onayladınız" : "Onaylanmadı" %>'></asp:Label>
                                </ItemTemplate>
                            </telerik:GridTemplateColumn>

                            <telerik:GridTemplateColumn SortExpression="YoneticiOnay" UniqueName="TemplateClmnYonetici" HeaderText="Yönetici Onayı">
                                <ItemTemplate>                                  
                                    <asp:Label ID="lblYoneticiOnayi" runat="server" Text='<%# Convert.ToBoolean(Eval("UstOnay")) == true ? "Yönetici Tarafından Onaylandı" : "Yönetici Tarafından Onaylanmadı" %>'></asp:Label>
                                </ItemTemplate>
                            </telerik:GridTemplateColumn>

                        </Columns>
                    </MasterTableView>
                </telerik:RadGrid>
            </div>
            <div class="DersSecimAlt">
                <telerik:RadButton Width="100px" ID="RadButton1" runat="server" Text="Seçileni Çıkar" OnClick="btnSecileniSil_Click"></telerik:RadButton>
                <telerik:RadButton Width="100px" ID="RadButton2" runat="server" Text="Dersleri Onayla" OnClick="btnDersleriOnayla_Click"></telerik:RadButton>
            </div>
        </telerik:RadPageView>
    </telerik:RadMultiPage>


    <telerik:RadNotification ID="RadNotificationDers" runat="server" EnableRoundedCorners="true"
        EnableShadow="true" Text="Sample content" Title="Bilgilendirme" Width="300" Height="100">
    </telerik:RadNotification>


</asp:Content>
