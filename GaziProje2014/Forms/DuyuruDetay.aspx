<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="DuyuruDetay.aspx.cs" Inherits="GaziProje2014.Forms.DuyuruDetay" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <script type="text/javascript">
        var RadGrid1;
        var DataItems;
        function gridCreated(sender, args) {
            RadGrid1 = sender;
        }
        function CheckItem(itemCheckBox) {
            var masterTableView = RadGrid1.get_masterTableView();
            if (DataItems == null) {
                DataItems = masterTableView.get_dataItems();
            }
            var row = itemCheckBox.parentNode.parentNode;
            if (row.tagName === "TR" && row.id != "") {
                var item = $find(row.id);
                if (!item.get_selected() && itemCheckBox.checked) {
                    masterTableView.clearSelectedItems();
                    item.set_selected(true);
                }
            }
        }
        function CheckAll(headerCheckBox) {
            var isChecked = headerCheckBox.checked;
            var checkboxes = RadGrid1.get_masterTableView().get_element().getElementsByTagName("INPUT");
            var index;
            for (index = 0; index < checkboxes.length; index++) {
                if (typeof (checkboxes[index].checked) !== "undefined") {
                    if (isChecked) {
                        checkboxes[index].checked = true;
                    }
                    else {
                        checkboxes[index].checked = false;
                    }
                }
            }
        }

    </script>

    <telerik:RadWindowManager ID="RadWindowManager1" runat="server" EnableShadow="true">
    </telerik:RadWindowManager>

    <style>
        .duyuruSolUst
        {
            position: absolute;
            top: 0px;
            left: 0px;
           
            width:250px;
            height:110px;

            color:white;
            z-index: 1;
        }

        .duyuruSolUstGolge 
        {
            position: absolute;
            top: 0px;
            left: 0px;

            width:250px;
            height:110px;

            background-color:black;
            opacity: 0.6; 
            filter: alpha(opacity=60);  
        }
        .duyuruSolAlt
        {
            position: absolute;
            top: 110px;
            left: 0px;           
            bottom: 40px; 
            width:250px;  
            overflow:hidden;  
            background-color:white;   
            opacity: 0.9; 
            filter: alpha(opacity=90); 
        }

        .duyuruEditor
        {
            position: absolute;
            top: 0px;
            left: 250px;           
            bottom: 40px; 
            right:0px; 
            overflow: scroll;
            overflow-x:hidden;            
            background-color:white;   
            opacity: 0.9; 
            filter: alpha(opacity=90); 
            z-index: 1;
        }
    </style>

    <div class="duyuruSolUst">
        <table class="tdTablo">
            <tr>
                <td>Duyuru Adı</td>
            </tr>
            <tr>
                <td>
                    <telerik:RadTextBox ID="txtDuyuruAdi" Width="190px" runat="server"></telerik:RadTextBox>
                </td>
            </tr>
            <tr>
                <td>Duyuru Tarihi</td>
            </tr>
            <tr>
                <td>
                    <telerik:RadDatePicker ID="dteDuyuruTarihi" Width="190px" runat="server"></telerik:RadDatePicker>
                </td>
            </tr>
        </table>
    </div>

    <div class="duyuruSolUstGolge">
    </div>

    <div class="duyuruSolAlt">
        <telerik:RadGrid ID="RadGrid1" runat="server" CssClass="Doldur">
            <ClientSettings EnableRowHoverStyle="true">
                <Selecting AllowRowSelect="True"></Selecting>
                <ClientEvents OnGridCreated="gridCreated" />
                <Scrolling UseStaticHeaders="True" AllowScroll="True"></Scrolling>
            </ClientSettings>
            <MasterTableView AutoGenerateColumns="False" DataKeyNames="KullaniciTipId">
                <Columns>
                    <telerik:GridTemplateColumn UniqueName="TemplateColumn" Reorderable="False" Groupable="False">
                        <HeaderStyle Width="30px"></HeaderStyle>
                        <ItemStyle HorizontalAlign="Center" VerticalAlign="Top"></ItemStyle>
                        <HeaderTemplate>
                            <input onclick="CheckAll(this);" type="checkbox">
                        </HeaderTemplate>
                        <ItemTemplate>
                            <asp:CheckBox ID="CheckBox1" onclick="CheckItem(this);" runat="server" AutoPostBack="False"></asp:CheckBox>
                        </ItemTemplate>
                    </telerik:GridTemplateColumn>
                    <telerik:GridBoundColumn DataField="KullaniciTipAdi" FilterControlAltText="Filter KullaniciTipAdi column" HeaderText="KullaniciTipAdi" SortExpression="KullaniciTipAdi" UniqueName="KullaniciTipAdi">
                        <ColumnValidationSettings>
                            <ModelErrorMessage Text="" />
                        </ColumnValidationSettings>
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="KullaniciTipId" Display="false" UniqueName="KullaniciTipId">
                    </telerik:GridBoundColumn>
                </Columns>
            </MasterTableView>
        </telerik:RadGrid>
    </div>

    <div class="duyuruEditor">
        <telerik:RadEditor runat="server" ID="RadEditor1" Width="99%" Height="685px">
            <CssFiles>
                    <telerik:EditorCssFile Value="../Style/css/Editors.css" />
            </CssFiles>
        </telerik:RadEditor>
    </div>

    <div class="contentAlt30">
        <telerik:RadButton ID="btnYayinla" runat="server" Text="Yayınla" OnClick="btnYayinla_Click"></telerik:RadButton>
        <telerik:RadButton ID="btnTemizle" runat="server" Text="Temizle" OnClick="btnTemizle_Click"></telerik:RadButton>
    </div>
    <div class="contentAlt30Golge"> 
    </div>

</asp:Content>
