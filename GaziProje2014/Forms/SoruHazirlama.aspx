<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="SoruHazirlama.aspx.cs" Inherits="GaziProje2014.Forms.SoruHazirlama" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


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
<%--     <telerik:RadListView ID="RadListView2" DataSourceID="SqlDataSource1" runat="server"
                            ItemPlaceholderID="CustomersContainer" DataKeyNames="CustomerID" AllowPaging="true"
                            OnItemCommand="RadListView1_ItemCommand">--%>
        <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">
            <script type="text/javascript">
                function RequestStart(sender, eventArgs) {
                    //disable ajax on update/insert operation to upload the image
                    if ((eventArgs.get_eventTarget().indexOf("Update") > -1) || (eventArgs.get_eventTarget().indexOf("PerformInsert") > -1)) {
                        eventArgs.set_enableAjax(false);
                    }
                }
            </script>
        </telerik:RadCodeBlock>

            <telerik:RadListView ID="RadListView1" runat="server" DataKeyNames="Id" DataSourceID="SqlDataSource1" Skin="Silk" OnItemDataBound="RadListView1_ItemDataBound">
                <LayoutTemplate>
                    <div style="width:800px;">
                        <ul>
                            <li id="itemPlaceholder" runat="server"></li>
                        </ul>
                        <div>
                            <asp:Button ID="btnInitInsert" runat="server" Text="Soru Ekle" OnClick="btnInitInsert_Click"/>
                        </div>
                        <div style="display: none">
                            <telerik:RadCalendar ID="rlvSharedCalendar" runat="server" RangeMinDate="<%#new DateTime(1900, 1, 1) %>" Skin="<%#Container.Skin %>" />
                        </div>
                        <div style="display: none">
                            <telerik:RadTimeView ID="rlvSharedTimeView" runat="server" Skin="<%# Container.Skin %>" />
                        </div>
                    </div>
                </LayoutTemplate>
                <ItemTemplate>                  
                        <fieldset class="fieldsetForm">
                            <p>
                            <legend class="legendForm">Soru Bir</legend>
<%--                             <a href='<%# "ResimGoruntule.aspx?ResimAdi=images/"+ Eval("DogruCvp")+ "&genislik=599" %>' title=""><%# Eval("DogruCvp") %></a>--%>                            
                            <asp:Image ID="imgSoruResim" runat="server" ImageUrl='<%# Eval("ResimSoru") %>' /><br />
                            
                            &nbsp;<asp:Label ID="IdLabel" runat="server" Text='<%# Eval("Id") %>' Visible="false" />
                            &nbsp;<asp:Label ID="SoruLabel" runat="server" Text='<%# Eval("Soru") %>' />
                            &nbsp;<asp:Label ID="KullaniciIdLabel" runat="server" Text='<%# Eval("KullaniciId") %>' Visible="false" />
                            &nbsp;<asp:Label ID="CvpSayisiLabel" runat="server" Text='<%# Eval("CvpSayisi") %>' />
                            &nbsp;<asp:Label ID="DogruCvpLabel" runat="server" Text='<%# Eval("DogruCvp") %>' Visible="false"/>
                            &nbsp;<asp:Label ID="KayitTrhLabel" runat="server" Text='<%# Eval("KayitTrh") %>' Visible="false"/>
                            </p>
                            <asp:RadioButtonList ID="rblCvp" runat="server">
                            </asp:RadioButtonList>
                            &nbsp;<asp:Label ID="Cvp1Label" runat="server" Text='<%# Eval("Cvp1") %>' Visible="false" />
                            &nbsp;<asp:Label ID="Cvp2Label" runat="server" Text='<%# Eval("Cvp2") %>'  Visible="false"/>
                            &nbsp;<asp:Label ID="Cvp3Label" runat="server" Text='<%# Eval("Cvp3") %>'  Visible="false"/>
                            &nbsp;<asp:Label ID="Cvp4Label" runat="server" Text='<%# Eval("Cvp4") %>'  Visible="false"/>
                            &nbsp;<asp:Label ID="Cvp5Label" runat="server" Text='<%# Eval("Cvp5") %>'  Visible="false"/>
                            <%--&nbsp;<asp:Label ID="ResimSoruLabel" runat="server" Text='<%# Eval("ResimSoru") %>' Visible="false" />--%>
                            <br /><asp:Button ID="btnEdit" runat="server" Text="Düzenle" CommandName="Edit"></asp:Button>

                        </fieldset>                 
                </ItemTemplate>
                <EditItemTemplate>

                    <fieldset class="fieldsetForm">
                        <legend  class="legendForm">Soru No:&nbsp;
                            <asp:TextBox ID="txtBoxCompany" runat="server" Text='<%#Bind("CvpSayisi")%>' Width="40px"></asp:TextBox>&nbsp;&nbsp;
                            <asp:RequiredFieldValidator ID="rvCompany" runat="server" ControlToValidate="txtBoxCompany"
                                ErrorMessage="Lütfen Soru Sırası Giriniz" Display="Dynamic"></asp:RequiredFieldValidator>
                        </legend>

                       <table style="width:550px;">
                           <tr>
                               <td>Soru Sıra</td>
                               <td>
                                   <asp:TextBox ID="txtSoruSira" runat="server" Text='<%#Bind("CvpSayisi")%>'></asp:TextBox>
                               </td>
                               <td>
                                   <asp:TextBox ID="txtResimYol" runat="server" Enabled="false" Text='<%#Bind("ResimSoru")%>'></asp:TextBox> 
                               </td>
                               <td></td>
                           </tr>
                           <tr>
                               <td>Soru Resim</td>
                               <td>
                                  <asp:FileUpload ID="flupldResim" runat="server" Width="182px"  />                                   
                               </td>
                               <td>
                                   <telerik:RadButton ID="btnResimYukle" runat="server" Text="Resmi Yükle" OnClick="btnResimYukle_Click"></telerik:RadButton>
                               </td>
                               <td>                                   
                                   <telerik:RadButton ID="btnResimSil" runat="server" Text="Resmi Sil" OnClick="btnResimSil_Click"></telerik:RadButton>
                               </td>
                           </tr>
                           <tr>
                               <td></td>
                               <td colspan="3">
                                   <asp:Image ID="imgSoruResim" runat="server" ImageUrl='<%# Eval("ResimSoru") %>' />
                               </td>
                           </tr>
                           <tr>
                              <td colspan="4">
                                 Soru:
                              </td>
                           </tr>
                           <tr>
                              <td colspan="4">
                                  <telerik:RadTextBox ID="txtSoru" runat="server" Height="69px" TextMode="MultiLine" Width="100%" Text='<%#Bind("Soru")%>'></telerik:RadTextBox>
                              </td>
                           </tr>
                           <tr>
                               <td colspan="4">
                                    
                                    <table style="width:100%">
                                        <tr>
                                            <td style="width:70px;">
                                                Cevap 1:
                                            </td>
                                            <td>
                                                <telerik:RadTextBox ID="txtCvp1" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text='<%#Bind("Cvp1")%>'></telerik:RadTextBox>
                                            </td>
                                        </tr>

                                        <tr>
                                            <td>
                                                Cevap 2:
                                            </td>
                                            <td>
                                                <telerik:RadTextBox ID="txtCvp2" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text='<%#Bind("Cvp2")%>'></telerik:RadTextBox>
                                            </td>
                                        </tr>

                                        <tr>
                                            <td>
                                                Cevap 3:
                                            </td>
                                            <td>
                                                <telerik:RadTextBox ID="RadTextBox1" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text='<%#Bind("Cvp3")%>'></telerik:RadTextBox>
                                            </td>
                                        </tr>

                                        <tr>
                                            <td>
                                                Cevap 4:
                                            </td>
                                            <td>
                                                <telerik:RadTextBox ID="txtCvp4" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text='<%#Bind("Cvp4")%>'></telerik:RadTextBox>
                                            </td>
                                        </tr>

                                        <tr>
                                            <td>
                                                Cevap 5:
                                            </td>
                                            <td>
                                                <telerik:RadTextBox ID="txtCvp5" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text='<%#Bind("Cvp5")%>'></telerik:RadTextBox>
                                            </td>
                                        </tr>
                                    </table>

                               </td>
                           </tr>
                           <tr>
                               <td>
                                  <asp:Button ID="btnUpdate" runat="server" Text="Update" CommandName="Update" Width="70px"></asp:Button>
                               </td>
                               <td>
                                   <asp:Button ID="BtnCancel" runat="server" Text="Cancel" CommandName="Cancel" CausesValidation="false" Width="70px"></asp:Button>
                               </td>
                               <td></td>
                               <td></td>
                           </tr>
                       </table>
                    </fieldset>

                </EditItemTemplate>
                <InsertItemTemplate>

                    <fieldset class="fieldsetForm">
                        <legend  class="legendForm">Soru No:&nbsp;
                            <asp:TextBox ID="TextBox1" runat="server" Text='<%#Bind("CvpSayisi")%>' Width="40px"></asp:TextBox>&nbsp;&nbsp;
                          
                        </legend>

                       <table style="width:550px;">
                           <tr>
                               <td>Soru Sıra</td>
                               <td>
                                   <asp:TextBox ID="TextBox2" runat="server" Text='<%#Bind("CvpSayisi")%>'></asp:TextBox>
                               </td>
                               <td>
                                   <asp:TextBox ID="txtResimYol" runat="server" Enabled="false" Text='<%#Bind("ResimSoru")%>'></asp:TextBox> 
                               </td>
                               <td></td>
                           </tr>
                           <tr>
                               <td>Soru Resim</td>
                               <td>
                                  <asp:FileUpload ID="flupldResim" runat="server" Width="182px"  />                                   
                               </td>
                               <td>
                                   <telerik:RadButton ID="RadButton1" runat="server" Text="Resmi Yükle" OnClick="btnResimYukle_Click"></telerik:RadButton>
                               </td>
                               <td>                                   
                                   <telerik:RadButton ID="btnResimSil" runat="server" Text="Resmi Sil" OnClick="btnResimSil_Click"></telerik:RadButton>
                               </td>
                           </tr>
                           <tr>
                               <td></td>
                               <td colspan="3">
                                   <asp:Image ID="imgSoruResim" runat="server" ImageUrl='<%# Eval("ResimSoru") %>' />
                               </td>
                           </tr>
                           <tr>
                              <td colspan="4">
                                 Soru:
                              </td>
                           </tr>
                           <tr>
                              <td colspan="4">
                                  <telerik:RadTextBox ID="RadTextBox2" runat="server" Height="69px" TextMode="MultiLine" Width="100%" Text='<%#Bind("Soru")%>'></telerik:RadTextBox>
                              </td>
                           </tr>
                           <tr>
                               <td colspan="4">
                                    
                                    <table style="width:100%">
                                        <tr>
                                            <td style="width:70px;">
                                                Cevap 1:
                                            </td>
                                            <td>
                                                <telerik:RadTextBox ID="RadTextBox3" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text='<%#Bind("Cvp1")%>'></telerik:RadTextBox>
                                            </td>
                                        </tr>

                                        <tr>
                                            <td>
                                                Cevap 2:
                                            </td>
                                            <td>
                                                <telerik:RadTextBox ID="RadTextBox4" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text='<%#Bind("Cvp2")%>'></telerik:RadTextBox>
                                            </td>
                                        </tr>

                                        <tr>
                                            <td>
                                                Cevap 3:
                                            </td>
                                            <td>
                                                <telerik:RadTextBox ID="RadTextBox5" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text='<%#Bind("Cvp3")%>'></telerik:RadTextBox>
                                            </td>
                                        </tr>

                                        <tr>
                                            <td>
                                                Cevap 4:
                                            </td>
                                            <td>
                                                <telerik:RadTextBox ID="RadTextBox6" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text='<%#Bind("Cvp4")%>'></telerik:RadTextBox>
                                            </td>
                                        </tr>

                                        <tr>
                                            <td>
                                                Cevap 5:
                                            </td>
                                            <td>
                                                <telerik:RadTextBox ID="RadTextBox7" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text='<%#Bind("Cvp5")%>'></telerik:RadTextBox>
                                            </td>
                                        </tr>
                                    </table>

                               </td>
                           </tr>
                           <tr>
                               <td>
                                  <asp:Button ID="btnEkle" runat="server" Text="Ekle" CommandName="PerformInsert"/>
                               </td>
                               <td>
                                   <asp:Button ID="BtnIptal" runat="server" Text="İptal" CommandName="Cancel" CausesValidation="false" Width="70px"></asp:Button>
                               </td>
                               <td></td>
                               <td></td>
                           </tr>
                       </table>
                    </fieldset>              
                </InsertItemTemplate>
                <EmptyDataTemplate>
                    <div class="RadListView RadListView_Office2010Black">
                        <div class="rlvEmpty">
                            Henüz Hiç Soru Girilmemiş
                        </div>
                    </div>
                </EmptyDataTemplate>
            </telerik:RadListView>
<%--            <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" SelectCommand="SELECT [Id], [Soru], [KullaniciId], [CvpSayisi], [DogruCvp], [KayitTrh], [Cvp1], [Cvp2], [Cvp3], [Cvp4], [ResimSoru] FROM [Sorular]"></asp:SqlDataSource>
--%>
        <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:GAZIConnectionString %>" DeleteCommand="DELETE FROM [Sorular] WHERE [Id] = @Id" InsertCommand="INSERT INTO [Sorular] ([KullaniciId], [Soru], [CvpSayisi], [DogruCvp], [KayitTrh], [Cvp1], [Cvp2], [ResimSoru], [Cvp5], [Cvp4], [Cvp3]) VALUES (@KullaniciId, @Soru, @CvpSayisi, @DogruCvp, @KayitTrh, @Cvp1, @Cvp2, @ResimSoru, @Cvp5, @Cvp4, @Cvp3)" SelectCommand="SELECT [Id], [KullaniciId], [Soru], [CvpSayisi], [DogruCvp], [KayitTrh], [Cvp1], [Cvp2], [ResimSoru], [Cvp5], [Cvp4], [Cvp3] FROM [Sorular]" UpdateCommand="UPDATE [Sorular] SET [KullaniciId] = @KullaniciId, [Soru] = @Soru, [CvpSayisi] = @CvpSayisi, [DogruCvp] = @DogruCvp, [KayitTrh] = @KayitTrh, [Cvp1] = @Cvp1, [Cvp2] = @Cvp2, [ResimSoru] = @ResimSoru, [Cvp5] = @Cvp5, [Cvp4] = @Cvp4, [Cvp3] = @Cvp3 WHERE [Id] = @Id">
            <DeleteParameters>
                <asp:Parameter Name="Id" Type="Int64" />
            </DeleteParameters>
            <InsertParameters>
                <asp:Parameter Name="KullaniciId" Type="Int32" />
                <asp:Parameter Name="Soru" Type="String" />
                <asp:Parameter Name="CvpSayisi" Type="Int32" />
                <asp:Parameter Name="DogruCvp" Type="String" />
                <asp:Parameter Name="KayitTrh" Type="DateTime" />
                <asp:Parameter Name="Cvp1" Type="String" />
                <asp:Parameter Name="Cvp2" Type="String" />
                <asp:Parameter Name="ResimSoru" Type="String" />
                <asp:Parameter Name="Cvp5" Type="String" />
                <asp:Parameter Name="Cvp4" Type="String" />
                <asp:Parameter Name="Cvp3" Type="String" />
            </InsertParameters>
            <UpdateParameters>
                <asp:Parameter Name="KullaniciId" Type="Int32" />
                <asp:Parameter Name="Soru" Type="String" />
                <asp:Parameter Name="CvpSayisi" Type="Int32" />
                <asp:Parameter Name="DogruCvp" Type="String" />
                <asp:Parameter Name="KayitTrh" Type="DateTime" />
                <asp:Parameter Name="Cvp1" Type="String" />
                <asp:Parameter Name="Cvp2" Type="String" />
                <asp:Parameter Name="ResimSoru" Type="String" />
                <asp:Parameter Name="Cvp5" Type="String" />
                <asp:Parameter Name="Cvp4" Type="String" />
                <asp:Parameter Name="Cvp3" Type="String" />
                <asp:Parameter Name="Id" Type="Int64" />
            </UpdateParameters>
        </asp:SqlDataSource>

    <asp:Image ID="Image1" runat="server" ImageUrl="~/Forms/SoruResimleri/OrnekSoru.jpg" />

</asp:Content>
