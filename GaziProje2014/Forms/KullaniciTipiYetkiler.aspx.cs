using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using Telerik.Web.UI;

namespace GaziProje2014.Forms
{
    public partial class KullaniciTipiYetkiler : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {                
                GAZIEntities gaziEntities = new GAZIEntities();
                List<GaziProje2014.Data.KullaniciTipleri> kullaniciTipleri = gaziEntities.KullaniciTipleri.ToList();
                RadGridKullaniciTipleri.DataSource = kullaniciTipleri;
                RadGridKullaniciTipleri.DataBind();
            }
        }

        protected void RadGridKullaniciTipleri_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (RadGridKullaniciTipleri.SelectedItems.Count > 0)
            {
               
                int secilikullaniciTipId = (int)RadGridKullaniciTipleri.SelectedValues["KullaniciTipId"];
                GAZIEntities gaziEntities = new GAZIEntities();

                //var kullaniciYetkiler = (from f in gaziEntities.Formlar
                //                         join kf in gaziEntities.KullaniciFormlar on f.Id equals  kf.FormId
                //                         where kf.KullaniciTipiId == secilikullaniciTipId && f.PId != null
                //                         select new{f.Id, f.PId, f.FormBaslik, kf.FormYetki, kf.KullaniciTipiId}).ToList();
                var kullaniciYetkiler = (from f in gaziEntities.Formlar
                                         from kf in gaziEntities.KullaniciFormlar
                                                                .Where(q => f.Id == q.FormId && q.KullaniciTipiId == secilikullaniciTipId)
                                                                .DefaultIfEmpty()
                                         //where kf.KullaniciTipiId == secilikullaniciTipId && f.PId != null
                                         where  f.PId != null
                                         select new { f.Id, f.PId, f.FormBaslik, kf.FormYetki, kf.KullaniciTipiId }).ToList();


                //** Left Join
                //var query = from u in context.Users
                //            from a in context.Addresses
                //                             .Where(x => u.Primary2Address == x.AddressiD)
                //                             .DefaultIfEmpty()
                //            from s in context.States
                //                             .Where(x => a.Address2State == x.StateID)
                //                             .DefaultIfEmpty()
                //            from c in context.Countries
                //                             .Where(x => a.CountryID == x.CountryID)
                //                             .DefaultIfEmpty()
                //            select u.UserName;

               
                grdYetkiler.DataSource = kullaniciYetkiler;
                grdYetkiler.DataBind();
            }
        }

        protected void grdYetkiler_ItemDataBound(object sender, GridItemEventArgs e)
        {
            if (e.Item is GridGroupHeaderItem)
            {
                int PId = (int)((System.Data.DataRowView)(e.Item.DataItem)).Row.ItemArray[0];

                GAZIEntities gaziEntities = new GAZIEntities();
                var pform = gaziEntities.Formlar.Where(q => q.Id == PId).FirstOrDefault();

                GridGroupHeaderItem hitem = (GridGroupHeaderItem)e.Item;
                Image img = (Image)hitem.FindControl("imgResim");
                img.ImageUrl = pform.FormImageUrl;

                Label lbl = (Label)hitem.FindControl("lblBaslik");
                lbl.Text = pform.FormBaslik;              
            }
        }

        protected void btnKaydet_Click(object sender, EventArgs e)
        {
            GAZIEntities gaziEntities = new GAZIEntities();
            int secilikullaniciTipId = (int)RadGridKullaniciTipleri.SelectedValues["KullaniciTipId"];

            foreach (GridDataItem item in grdYetkiler.MasterTableView.Items)
            {
                CheckBox chk = (CheckBox)item["chkTemplateColumn"].FindControl("chkYetki");
                int formId = Convert.ToInt32(item["Id"].Text);
                //int kullaniciTipiId = Convert.ToInt32(item["KullaniciTipiId"].Text);
                
                KullaniciFormlar kullaniciFormlar = gaziEntities.KullaniciFormlar.Where(q => q.FormId == formId && q.KullaniciTipiId == secilikullaniciTipId).FirstOrDefault();                
                if (kullaniciFormlar == null)
                {
                    kullaniciFormlar = new KullaniciFormlar();
                    kullaniciFormlar.KullaniciTipiId = secilikullaniciTipId;
                    kullaniciFormlar.FormId = formId;
                    kullaniciFormlar.FormYetki = chk.Checked;
                    gaziEntities.KullaniciFormlar.Add(kullaniciFormlar);               
                }
                else
                {
                    kullaniciFormlar.FormYetki = chk.Checked;              
                }            
            }
            gaziEntities.SaveChanges();

            //** Cache Temizlemek
            string kullaniciMenu = "Menu" + secilikullaniciTipId.ToString();
            if (Cache[kullaniciMenu] != null)
                Cache.Remove(kullaniciMenu);

            ShowMesaj("Yetkiler Başarıyla Güncellendi");
        }

        private void ShowMesaj(string Mesaj)
        {
            RadNotification1.Text = Mesaj;
            RadNotification1.Show();
        }

    }
}