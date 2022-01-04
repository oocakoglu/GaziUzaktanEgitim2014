using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using Telerik.Web.UI;

namespace GaziProje2014
{
    public partial class SiteCss : System.Web.UI.MasterPage
    {


        //testSpace.Style.Add("display", "none");


        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            string backGround = "background: url(/Style/Images/ArkaPlan2.jpg) no-repeat center center fixed;";
            if (Session["BackGround"] != null)
            {
                backGround = Session["BackGround"].ToString();
                backGround = "background: url(" + backGround + ") no-repeat center center fixed;";
            }

            HtmlGenericControl itemStyle = new HtmlGenericControl("style");
            itemStyle.Attributes.Add("type", "text/css");
            itemStyle.InnerHtml = "html "
                                + "{"
                                + backGround
                                + "-webkit-background-size: cover;"
                                + "-moz-background-size: cover;"
                                + "-o-background-size: cover;"
                                + "background-size: cover;"
                                + "height: 100%;"
                                + "}";


            Page.Header.Controls.Add(itemStyle);
            if (Session["SkinName"] != null)
                QsfSkinManager.Skin = Session["SkinName"].ToString();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {


                // int KullaniciTipiId = 1;
                int KullaniciTipiId = Convert.ToInt32(Session["KullaniciTipiId"].ToString());   
                
                string kullaniciMenu = "Menu" + KullaniciTipiId.ToString();
                List<Formlar> lstForm;

                //DataTable dtForm;
                lstForm = (List<Formlar>)Cache[kullaniciMenu];
                if (lstForm == null)
                {
                    string ConStr = ConfigurationManager.ConnectionStrings["GAZIConnectionString"].ConnectionString;
                    string SqlText = "SELECT F.Id, F.PId, F.FormAdi, F.FormBaslik, F.FormAciklama, F.FormImageUrl FROM Formlar F    "
                                   + "INNER JOIN KullaniciFormlar KF ON F.Id = KF.FormId     "
                                   + "WHERE KF.KullaniciTipiId = " + KullaniciTipiId.ToString() + " And KF.FormYetki = 1 And PId IS NOT NULL    "
                                   + "UNION   "
                                   + "Select Id, PId, FormAdi, FormBaslik, FormAciklama, FormImageUrl From Formlar Where Id IN  "
                                   + "(SELECT  F.PId FROM Formlar F    "
                                   + "INNER JOIN KullaniciFormlar KF ON F.Id = KF.FormId     "
                                   + "WHERE KF.KullaniciTipiId = " + KullaniciTipiId.ToString() + " And KF.FormYetki = 1 And PId IS NOT NULL )  ";
                    SqlDataAdapter daForm = new SqlDataAdapter(SqlText, ConStr);
                    DataTable dtForm = new DataTable();
                    daForm.Fill(dtForm);

                    lstForm = dtForm.AsEnumerable().Select(row =>
                        new Formlar
                        {
                            Id = row.Field<int>("Id"),
                            PId = row.Field<int?>("PId"),
                            FormAdi = row.Field<string>("FormAdi"),
                            FormBaslik = row.Field<string>("FormBaslik"),
                            FormAciklama = row.Field<string>("FormAciklama"),
                            FormImageUrl = row.Field<string>("FormImageUrl")
                        }).ToList();
                    Cache.Insert(kullaniciMenu, lstForm, null, DateTime.Now.AddMinutes(5), TimeSpan.Zero);
                }
                FormCreateNode(null, null, lstForm);
                string url = Request.Url.ToString();

                //** Giriş Sayası ise
                if (url.IndexOf("DefaultDuyuru") > 0)
                {
                    if (RadPanelBar1.Items.Count > 0)
                    {
                        RadPanelItem rdust = RadPanelBar1.Items[0];
                        rdust.Expanded = true;
                    }
                }
                else
                {
                    int ind = url.IndexOf("/Forms/");
                    url = url.Substring(ind, url.Length - ind);

                    RadPanelItem rdi = RadPanelBar1.FindItemByUrl(url);
                    if (rdi != null)    
                    {
                        RadPanelItem rdust = (RadPanelItem)rdi.Parent;
                        rdust.Expanded = true;
                    }
                }



                //RadPanelItem DersItem = new RadPanelItem();
                //DersItem.ImageUrl = "http://demos.telerik.com/aspnet-ajax/panelbar/examples/overview/Images/notes.gif";
                //DersItem.Text = "Ders Ağaç Yapısı";
                //DersItem.CssClass = "MainItem";
                //RadPanelBar1.Items.Add(DersItem);

                //RadPanelItem KonuItem = new RadPanelItem();
                ////KonuItem.Text = "Hours : " + DateTime.Now.Hour.ToString();
                //DersItem.Items.Add(KonuItem);
                //KonuItem.DataBind();

                //DersItem.Expanded = true;
            }



            if (Session["Mesaj"] != null)
            {
                RadNotification1.Text = Session["Mesaj"].ToString();
                RadNotification1.Show();
                Session.Remove("Mesaj");
            }


        }
        
        private void FormCreateNode(int? AktifParentId, RadPanelItem RootNode, List<Formlar> FormList)
        {

            List<Formlar> FormBaslik = FormList.Where(x => x.PId == AktifParentId).ToList();

            foreach (Formlar items in FormBaslik)
            {
                RadPanelItem dateItem = new RadPanelItem();
                dateItem.Text = items.FormBaslik;
                dateItem.CssClass = "MainItem";
                dateItem.NavigateUrl = items.FormAdi;

                if (items.FormImageUrl != null && items.FormImageUrl != "")
                    dateItem.ImageUrl = items.FormImageUrl;
                else
                    dateItem.ImageUrl = "http://demos.telerik.com/aspnet-ajax/panelbar/examples/overview/Images/contacts.gif";
                //RadPanelBar1.Items.Add(dateItem);

                if (RootNode != null)
                    RootNode.Items.Add(dateItem);
                else
                    RadPanelBar1.Items.Add(dateItem);

                FormCreateNode(items.Id, dateItem, FormList);
            }
        }

        protected void CikisButton_Click(object sender, ImageClickEventArgs e)
        {
            Session.Remove("KullaniciAdi");
            Session.Remove("KullaniciId");
            Session.Remove("KullaniciTipiId");
            Session.Remove("SkinName");
            Session.Remove("BackGround");

            //Response.Redirect("~/Login.aspx");
            //Response.Redirect("~/HizliGiris.aspx");
            Response.Redirect("~/Default.aspx");
        }

        protected void QsfSkinManager_SkinChanged(object sender, SkinChangedEventArgs e)
        {
            GAZIEntities gaziEntities = new GAZIEntities();
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            Kullanicilar kullanici = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == kullaniciId).FirstOrDefault();
            kullanici.SkinName = e.Skin;
            gaziEntities.SaveChanges();

            Session.Add("SkinName", e.Skin);
        }

        //private class Formlar
        //{
        //    public int Id { get; set; }
        //    public int? PId { get; set; }
        //    public string FormAdi { get; set; }
        //    public string FormBaslik { get; set; }
        //    public string FormAciklama { get; set; }
        //    public string FormImageUrl { get; set; }
        //}

        //protected override void OnInit(EventArgs e)
        //{
        //    RadPanelBar1.ItemTemplate = new TextBoxTemplate(); base.OnInit(e);
        //}

        //class TextBoxTemplate : ITemplate
        //{
        //    public void InstantiateIn(Control container)
        //    {
        //        string ConStr = ConfigurationManager.ConnectionStrings["GAZIConnectionString"].ConnectionString;
        //        SqlDataAdapter daForm = new SqlDataAdapter("SELECT Id, PId, FormAdi, FormBaslik, FormAciklama, FormImageUrl FROM Formlar", ConStr);
        //        DataTable dtForm = new DataTable();
        //        daForm.Fill(dtForm);

        //        RadTreeView radTreeView = new RadTreeView();
        //        radTreeView.ID = "radTreeView1";
        //        radTreeView.DataFieldID = "Id";
        //        radTreeView.DataFieldParentID = "PId";
        //        radTreeView.DataNavigateUrlField = "FormAdi";
        //        radTreeView.DataTextField = "FormBaslik";
        //        radTreeView.DataValueField = "Id";

        //        radTreeView.DataSource = dtForm;
        //        container.Controls.Add(radTreeView);
        //    }

        //}
        

    }
}