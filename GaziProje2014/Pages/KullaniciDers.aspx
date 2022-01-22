<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="KullaniciDers.aspx.cs" Inherits="GaziProje2014.Pages.KullaniciDers" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

     <style>
         .pnlTip
         {
             padding:10px;
            background-image: url('/Style/Images/ust_bar.png');
            background-repeat: repeat-x;
            background-size:contain;        
         } 
     </style>

 <telerik:RadSplitter ID="wrapperSplitter" runat="server" Width="100%" Height="100%" Orientation="Horizontal">
      
        <telerik:RadPane ID="DersHeader" runat="server" Height="30px" CssClass="pnlTip">
            <div >
                <telerik:RadDropDownList ID="RadDropDownList2" runat="server" Width="200px" DropDownWidth="200px"
                    DropDownHeight="200px"  DataTextField="KullaniciTipAdi" DefaultMessage="Seçiniz..."
                    DataValueField="KullaniciTipId" DataSourceID="SqlDataSourceKullaniciTipi">
                </telerik:RadDropDownList>
                
                <asp:Button runat="server" Text="Select" ID="Button2"  />

            </div>
        </telerik:RadPane>

        <telerik:RadPane ID="Content" runat="server" >
                
            <telerik:RadSplitter ID="RadSplitter1" runat="server" Height="100%" Width="100%">
                <telerik:RadPane ID="RadPane1" runat="server" Width="20%" Height="100%">
                    <div class="qsf-demo-canvas">
<%--                        <telerik:RadPanelBar runat="server" ID="RadPanelBar1"  Height="100%" Width="100%" ExpandMode="FullExpandedItem" >                                                    
                        </telerik:RadPanelBar>--%>
                        <telerik:RadGrid ID="RadGrid1" runat="server" Height="100%" Width="100%" CellSpacing="0" DataSourceID="SqlKullanicilar" GridLines="None">
                            
                            <ClientSettings>
                                <Selecting AllowRowSelect="True" />
                            </ClientSettings>

                            <MasterTableView AutoGenerateColumns="False" DataKeyNames="KullaniciId" DataSourceID="SqlKullanicilar">
                                <Columns>
                                    <telerik:GridBoundColumn DataField="Adi" FilterControlAltText="Filter Adi column" HeaderText="Adi" SortExpression="Adi" UniqueName="Adi">
                                        <ColumnValidationSettings>
                                            <ModelErrorMessage Text="" />
                                        </ColumnValidationSettings>
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn DataField="Soyadi" FilterControlAltText="Filter Soyadi column" HeaderText="Soyadi" SortExpression="Soyadi" UniqueName="Soyadi">
                                        <ColumnValidationSettings>
                                            <ModelErrorMessage Text="" />
                                        </ColumnValidationSettings>
                                    </telerik:GridBoundColumn>
                                </Columns>
                            </MasterTableView>
                        </telerik:RadGrid>


                    </div>
                </telerik:RadPane>
               
                <telerik:RadSplitBar ID="RadSplitbar1" runat="server" CollapseMode="Forward">
                </telerik:RadSplitBar>
              
                <telerik:RadPane ID="contentPane" runat="server" Width="80%" Height="100%">   
                   <div class="qsf-demo-canvas">    
                       <telerik:RadGrid ID="RadGrid2" runat="server" CellSpacing="0" DataSourceID="SqlDataSourceDersler" GridLines="None">
                           <MasterTableView AutoGenerateColumns="False" DataKeyNames="DersId" DataSourceID="SqlDataSourceDersler">
                               <Columns>
                                   <telerik:GridBoundColumn DataField="DersId" DataType="System.Int32" FilterControlAltText="Filter DersId column" HeaderText="DersId" ReadOnly="True" SortExpression="DersId" UniqueName="DersId">
                                       <ColumnValidationSettings>
                                           <ModelErrorMessage Text="" />
                                       </ColumnValidationSettings>
                                   </telerik:GridBoundColumn>
                                   <telerik:GridBoundColumn DataField="DersAdi" FilterControlAltText="Filter DersAdi column" HeaderText="DersAdi" SortExpression="DersAdi" UniqueName="DersAdi">
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
                </telerik:RadPane>   
                              
            </telerik:RadSplitter>                
        </telerik:RadPane>
            
           
        </telerik:RadSplitter>


        <asp:SqlDataSource ID="SqlKullanicilar" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" SelectCommand="SELECT [KullaniciAdi], [KullaniciId], [Adi], [Soyadi] FROM [Kullanicilar]"></asp:SqlDataSource>
        <asp:SqlDataSource ID="SqlDataSourceKullaniciTipi" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" SelectCommand="SELECT [KullaniciTipId], [KullaniciTipAdi] FROM [KullaniciTipleri]"></asp:SqlDataSource>
        <asp:SqlDataSource ID="SqlDataSourceDersler" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" SelectCommand="SELECT [DersId], [DersAdi], [DersAciklama] FROM [Dersler]"></asp:SqlDataSource>

</asp:Content>
