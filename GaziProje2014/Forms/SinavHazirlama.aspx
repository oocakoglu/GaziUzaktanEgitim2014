<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="SinavHazirlama.aspx.cs" Inherits="GaziProje2014.Forms.SinavHazirlama" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


    <style>
        .clear {
            clear: both;
        }

        .DuyuruOrta {
            position: absolute;
            top: 0px;
            left: 0px;
            right: 0px;
            bottom: 40px;
        }

        .DuyuruAlt {
            height: 30px;
            padding: 5px;
            position: absolute;
            bottom: 0px;
            right: 0px;
            left: 0px;
        }

        .DuyuruOrtaSol {
            position: absolute;
            top: 0px;
            left: 0px;
            bottom: 0px;
            width: 200px;
            background-color:red;
        }



        .DuyuruOrtaGovde {
            position: absolute;
            top: 0px;
            left: 200px;
            bottom: 0px;
            right: 0px;
            background-color: green;
        }

        .Doldur {
            height: 100%;
        }
    </style>


    <div class="DuyuruOrta">
        <div class="DuyuruOrtaSol">
            <telerik:RadGrid ID="RadGrid1" runat="server" DataSourceID="SqlDataSource1">
                <ClientSettings>
                    <Selecting AllowRowSelect="True" />
                </ClientSettings>
                <MasterTableView AutoGenerateColumns="False" DataKeyNames="SoruId" DataSourceID="SqlDataSource1">
                    <Columns> 
                        <telerik:GridBoundColumn DataField="SoruSira" DataType="System.Int32" HeaderText="SoruSira" UniqueName="SoruSira">
                            <ColumnValidationSettings>
                                <ModelErrorMessage Text="" />
                            </ColumnValidationSettings>
                        </telerik:GridBoundColumn>
                    </Columns>
                </MasterTableView>
            </telerik:RadGrid>

            <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" SelectCommand="SELECT [SoruId], [SoruSira] FROM [SinavSorular]"></asp:SqlDataSource>

        </div>
        <div class="DuyuruOrtaGovde">   
            
            <telerik:RadTabStrip ID="RadTabStrip2" runat="server" MultiPageID="RadMultiPage1">
                <Tabs>
                    <telerik:RadTab Text="Soru Duzenleme" Width="150px" PageViewID="RadPageView1"></telerik:RadTab>
                    <telerik:RadTab Text="Soru Önizleme" Width="150px" PageViewID="RadPageView2"></telerik:RadTab>
                </Tabs>
            </telerik:RadTabStrip>
            <telerik:RadMultiPage ID="RadMultiPage1" runat="server" SelectedIndex="0">  
                <telerik:RadPageView ID="RadPageView1" runat="server" Height="400px">
                </telerik:RadPageView>
                <telerik:RadPageView ID="RadPageView2" runat="server" Height="400px">     
                </telerik:RadPageView>                         
            </telerik:RadMultiPage>    
                         
        </div>
    </div>
    <div class="DuyuruAlt">
        <telerik:RadButton ID="btnYeniSoru" runat="server" Text="Yeni Soru"></telerik:RadButton>
        <telerik:RadButton ID="btnKaydet" runat="server" Text="Kaydet"></telerik:RadButton>
        <telerik:RadButton ID="btnSil" runat="server" Text="Sil"></telerik:RadButton>
    </div>

</asp:Content>
