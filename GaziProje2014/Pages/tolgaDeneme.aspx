<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="tolgaDeneme.aspx.cs" Inherits="GaziProje2014.Pages.tolgaDeneme" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <style>
            .legendForm {
                padding: 4px;
                position: absolute;
                left: 10px;
                top: -11px;
                background-color: #2DABC1; /*#4F709F;*/
                color: white;
                -webkit-border-radius: 4px;
                -moz-border-radius: 4px;
                border-radius: 4px;
                box-shadow: 2px 2px 4px #888;
                -moz-box-shadow: 2px 2px 4px #888;
                -webkit-box-shadow: 2px 2px 4px #888;
                text-shadow: 1px 1px 1px #333;
            }

            .fieldsetForm {
                position: relative;
                padding: 10px;
                margin-bottom: 30px;
                background: #F6F6F6;
                -webkit-border-radius: 8px;
                -moz-border-radius: 8px;
                border-radius: 8px;
                background: -webkit-gradient(linear, left top, left bottom, from(#EFEFEF), to(#FFFFFF));
                background: -moz-linear-gradient(center top, #EFEFEF, #FFFFFF 100%);
                box-shadow: 3px 3px 10px #ccc;
                -moz-box-shadow: 3px 3px 10px #ccc;
                -webkit-box-shadow: 3px 3px 10px #ccc;
            }
        </style>
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server">
            <Scripts>
                <asp:ScriptReference Assembly="Telerik.Web.UI" Name="Telerik.Web.UI.Common.Core.js"></asp:ScriptReference>
                <asp:ScriptReference Assembly="Telerik.Web.UI" Name="Telerik.Web.UI.Common.jQuery.js"></asp:ScriptReference>
                <asp:ScriptReference Assembly="Telerik.Web.UI" Name="Telerik.Web.UI.Common.jQueryInclude.js"></asp:ScriptReference>
            </Scripts>
        </telerik:RadScriptManager>
        <div style="height: 1000px">

            <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" SelectCommand="SELECT [Id], [Soru], [ResimSoru] FROM [Sorular]"></asp:SqlDataSource>
            <telerik:RadListView ID="RadListView1" runat="server" AllowMultiItemSelection="True" AllowPaging="True" DataKeyNames="Id" DataSourceID="SqlDataSource1" Skin="Outlook">
                <LayoutTemplate>
                    <div class="RadListView RadListView_Outlook">
                        <div id="itemPlaceholder" runat="server">
                        </div>
                    </div>
                </LayoutTemplate>
                <ItemTemplate>
                    <div class="rlvI">
                        <fieldset class="fieldsetForm">
                            <p>
                                <legend class="legendForm">Soru Bir</legend>
                                &nbsp;<asp:Button ID="SelectButton" runat="server" CausesValidation="False" CommandName="Select" CssClass="rlvBSel" Text=" " ToolTip="Select" />
                                &nbsp;<asp:Label ID="IdLabel" runat="server" Text='<%# Eval("Id") %>' Visible="false" />
                                &nbsp;<asp:Label ID="SoruLabel" runat="server" Text='<%# Eval("Soru") %>' />
                                &nbsp;<asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("ResimSoru") %>' />
                            </p>
                        </fieldset>
                    </div>
                </ItemTemplate>
                <AlternatingItemTemplate>
                    <div class="rlvA">
                        <fieldset class="fieldsetForm">
                            <p>
                                <legend class="legendForm">Soru Bir</legend>
                                &nbsp;<asp:Button ID="SelectButton" runat="server" CausesValidation="False" CommandName="Select" CssClass="rlvBSel" Text=" " ToolTip="Select" />
                                &nbsp;<asp:Label ID="IdLabel" runat="server" Text='<%# Eval("Id") %>' Visible="false" />
                                &nbsp;<asp:Label ID="SoruLabel" runat="server" Text='<%# Eval("Soru") %>' />
                                &nbsp;<asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("ResimSoru") %>' />
                            </p>
                        </fieldset>
                    </div>
                </AlternatingItemTemplate>
                <EmptyDataTemplate>
                    <div class="RadListView RadListView_Outlook">
                        <div class="rlvEmpty">
                            There are no items to be displayed.
                        </div>
                    </div>
                </EmptyDataTemplate>
                <SelectedItemTemplate>
                    <div class="rlvISel">
                        <fieldset class="fieldsetForm">
                            <p>
                                <legend class="legendForm">Soru Bir</legend>
                                &nbsp;<asp:Button ID="DeselectButton" runat="server" CausesValidation="False" CommandName="Deselect" CssClass="rlvBSel" Text=" " ToolTip="Deselect" />
                                &nbsp;<asp:Label ID="IdLabel" runat="server" Text='<%# Eval("Id") %>' />
                                &nbsp;<asp:Label ID="SoruLabel" runat="server" Text='<%# Eval("Soru") %>' />
                                &nbsp;<asp:Image ID="Image1" runat="server" ImageUrl='<%# Eval("ResimSoru") %>' />
                            </p>
                        </fieldset>
                    </div>
                </SelectedItemTemplate>
            </telerik:RadListView>
            <fieldset class="fieldsetForm">
                <p>
                    <legend class="legendForm">Sınav Adı</legend>
                    <telerik:RadTextBox ID="txtSinavAdi" runat="server"></telerik:RadTextBox>
                    <telerik:RadButton ID="btnSecilen" runat="server" Text="Sınav Kaydet" OnClick="btnSecilen_Click">
                    </telerik:RadButton>
                </p>
            </fieldset>
            <asp:SqlDataSource ID="SqlDataSource2" runat="server" ConflictDetection="CompareAllValues" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>"
                DeleteCommand="DELETE FROM [Sinav] WHERE [Id] = @original_Id AND (([KullaniciId] = @original_KullaniciId) OR ([KullaniciId] IS NULL AND @original_KullaniciId IS NULL)) AND (([SinavAdi] = @original_SinavAdi) OR ([SinavAdi] IS NULL AND @original_SinavAdi IS NULL)) AND (([KayitTrh] = @original_KayitTrh) OR ([KayitTrh] IS NULL AND @original_KayitTrh IS NULL))"
                InsertCommand="INSERT INTO [Sinav] ([KullaniciId], [SinavAdi], [KayitTrh]) VALUES (@KullaniciId, @SinavAdi, @KayitTrh)" OldValuesParameterFormatString="original_{0}" OnInserted="SqlDataSource2_Inserted"
                SelectCommand="SELECT [KullaniciId], [SinavAdi], [KayitTrh], [Id] FROM [Sinav]" UpdateCommand="UPDATE [Sinav] SET [KullaniciId] = @KullaniciId, [SinavAdi] = @SinavAdi, [KayitTrh] = @KayitTrh WHERE [Id] = @original_Id AND (([KullaniciId] = @original_KullaniciId) OR ([KullaniciId] IS NULL AND @original_KullaniciId IS NULL)) AND (([SinavAdi] = @original_SinavAdi) OR ([SinavAdi] IS NULL AND @original_SinavAdi IS NULL)) AND (([KayitTrh] = @original_KayitTrh) OR ([KayitTrh] IS NULL AND @original_KayitTrh IS NULL))">
                <DeleteParameters>
                    <asp:Parameter Name="original_Id" Type="Int64" />
                    <asp:Parameter Name="original_KullaniciId" Type="Int32" />
                    <asp:Parameter Name="original_SinavAdi" Type="String" />
                    <asp:Parameter Name="original_KayitTrh" Type="DateTime" />
                </DeleteParameters>
                <InsertParameters>
                    <asp:Parameter Name="KullaniciId" Type="Int32" />
                    <asp:Parameter Name="SinavAdi" Type="String" />
                    <asp:Parameter Name="KayitTrh" Type="DateTime" />
                </InsertParameters>
                <UpdateParameters>
                    <asp:Parameter Name="KullaniciId" Type="Int32" />
                    <asp:Parameter Name="SinavAdi" Type="String" />
                    <asp:Parameter Name="KayitTrh" Type="DateTime" />
                    <asp:Parameter Name="original_Id" Type="Int64" />
                    <asp:Parameter Name="original_KullaniciId" Type="Int32" />
                    <asp:Parameter Name="original_SinavAdi" Type="String" />
                    <asp:Parameter Name="original_KayitTrh" Type="DateTime" />
                </UpdateParameters>
            </asp:SqlDataSource>
            <asp:HiddenField ID="hdnSinavId" runat="server" />
            <asp:SqlDataSource ID="SqlDataSource3" runat="server" ConflictDetection="CompareAllValues" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" DeleteCommand="DELETE FROM [Sinav_Detay] WHERE [Id] = @original_Id AND (([SinavId] = @original_SinavId) OR ([SinavId] IS NULL AND @original_SinavId IS NULL)) AND (([SorularId] = @original_SorularId) OR ([SorularId] IS NULL AND @original_SorularId IS NULL))" InsertCommand="INSERT INTO [Sinav_Detay] ([SinavId], [SorularId]) VALUES (@SinavId, @SorularId)" OldValuesParameterFormatString="original_{0}" SelectCommand="SELECT [Id], [SinavId], [SorularId] FROM [Sinav_Detay]" UpdateCommand="UPDATE [Sinav_Detay] SET [SinavId] = @SinavId, [SorularId] = @SorularId WHERE [Id] = @original_Id AND (([SinavId] = @original_SinavId) OR ([SinavId] IS NULL AND @original_SinavId IS NULL)) AND (([SorularId] = @original_SorularId) OR ([SorularId] IS NULL AND @original_SorularId IS NULL))">
                <DeleteParameters>
                    <asp:Parameter Name="original_Id" Type="Int64" />
                    <asp:Parameter Name="original_SinavId" Type="Int64" />
                    <asp:Parameter Name="original_SorularId" Type="Int64" />
                </DeleteParameters>
                <InsertParameters>
                    <asp:Parameter Name="SinavId" Type="Int64" />
                    <asp:Parameter Name="SorularId" Type="Int64" />
                </InsertParameters>
                <UpdateParameters>
                    <asp:Parameter Name="SinavId" Type="Int64" />
                    <asp:Parameter Name="SorularId" Type="Int64" />
                    <asp:Parameter Name="original_Id" Type="Int64" />
                    <asp:Parameter Name="original_SinavId" Type="Int64" />
                    <asp:Parameter Name="original_SorularId" Type="Int64" />
                </UpdateParameters>
            </asp:SqlDataSource>
        </div>
    </form>
</body>
</html>
