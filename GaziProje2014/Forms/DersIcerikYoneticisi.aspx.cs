using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using GaziProje2014.Data.Models;
using Telerik.Web.UI;

namespace GaziProje2014.Forms
{
    public partial class DersIcerikYoneticisi : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
                GAZIDbContext gaziEntities = new GAZIDbContext();

                //** Öğretmenin daha önce seçtiği dersler
                var dersSecimListesi = (from od in gaziEntities.OgretmenDersler
                                        join d in gaziEntities.Dersler on od.DersId equals d.DersId
                                        //join k in gaziEntities.Kullanicilar on od.OgretmenId equals k.KullaniciId
                                        where od.UstOnay == true && od.OgretmenId == kullaniciId
                                        select new { od.OgretmenDersId, d.DersAdi }).ToList();


                rdcmbOgretmenOnayliDersler.DataSource = dersSecimListesi;
                rdcmbOgretmenOnayliDersler.DataTextField = "DersAdi";
                rdcmbOgretmenOnayliDersler.DataValueField = "OgretmenDersId";
                rdcmbOgretmenOnayliDersler.DataBind();

                //** Load Status
                if (Session["OgretmenDersId"] != null)
                {
                    rdcmbOgretmenOnayliDersler.SelectedValue = Session["OgretmenDersId"].ToString();
                }
                else
                {
                    if (rdcmbOgretmenOnayliDersler.SelectedValue != "")
                        Session.Add("OgretmenDersId", rdcmbOgretmenOnayliDersler.SelectedValue);
                }
                rdcmbOgretmenOnayliDersler_SelectedIndexChanged(null, null);

            }
        }

        protected void rdcmbOgretmenOnayliDersler_SelectedIndexChanged(object sender, RadComboBoxSelectedIndexChangedEventArgs e)
        {
            string ogretmenDersIdStr = rdcmbOgretmenOnayliDersler.SelectedValue;
            if (ogretmenDersIdStr != "")
            {
                int ogretmenDersId = Convert.ToInt32(ogretmenDersIdStr);

                GAZIDbContext gaziEntities = new GAZIDbContext();
                //** Konular Yukleniyor
                var konular = (from di in gaziEntities.DersIcerikler
                               where di.OgretmenDersId == ogretmenDersId
                               select new { di.IcerikId, di.IcerikPId, di.IcerikAdi, di.KayitTarihi, di.IconUrl }).Take(250).ToList();

                dersIcerikTreeList.DataSource = konular;
                dersIcerikTreeList.DataBind();
                dersIcerikTreeList.ExpandAllItems();
                Session.Add("OgretmenDersId", ogretmenDersIdStr);
            }

        }

        protected void dersIcerikTreeList_NeedDataSource(object sender, TreeListNeedDataSourceEventArgs e)
        {
            string ogretmenDersIdStr = rdcmbOgretmenOnayliDersler.SelectedValue;
            if (ogretmenDersIdStr != "")
            {
                int ogretmenDersId = Convert.ToInt32(ogretmenDersIdStr);

                GAZIDbContext gaziEntities = new GAZIDbContext();
                //** Konular Yukleniyor
                var konular = (from di in gaziEntities.DersIcerikler
                               where di.OgretmenDersId == ogretmenDersId
                               select new { di.IcerikId, di.IcerikPId, di.IcerikAdi, di.KayitTarihi, di.IconUrl }).Take(250).ToList();

                dersIcerikTreeList.DataSource = konular;
            }
        }
        
        protected void btnIcerikEkle_Click(object sender, EventArgs e)
        {
            Response.Redirect("~/Forms/DersIcerikDetay.aspx");
        }

        protected void btnIcerikDuzenle_Click(object sender, EventArgs e)
        {
            if (dersIcerikTreeList.SelectedItems.Count > 0)
            {
                string icerikId = dersIcerikTreeList.SelectedItems[0].GetDataKeyValue("IcerikId").ToString();
                Session.Add("DersIcerikId", Convert.ToInt32(icerikId));
                Response.Redirect("~/Forms/DersIcerikDetay.aspx");
            }
        }

        protected void btnIcerikSil_Click(object sender, EventArgs e)
        {
            if (dersIcerikTreeList.SelectedItems.Count > 0)
            {
                GAZIDbContext gaziEntities = new GAZIDbContext();
                string icerikIdStr = dersIcerikTreeList.SelectedItems[0].GetDataKeyValue("IcerikId").ToString();
                int icerikId = Convert.ToInt32(icerikIdStr);
                List<DersIcerikler> dersIcerikler = gaziEntities.DersIcerikler.Where(q => q.IcerikPId == icerikId || q.IcerikId == icerikId).ToList();
                foreach (var dersIcerik in dersIcerikler)
                {
                    gaziEntities.DersIcerikler.Remove(dersIcerik);
                }
                gaziEntities.SaveChanges();
                rdcmbOgretmenOnayliDersler_SelectedIndexChanged(null, null);
            }
        }

        protected void btnDersIcerikGoruntule_Click(object sender, EventArgs e)
        {
            if (dersIcerikTreeList.SelectedItems.Count > 0)
            {
                string icerikId = dersIcerikTreeList.SelectedItems[0].GetDataKeyValue("IcerikId").ToString();
                Session.Add("DersIcerikId", Convert.ToInt32(icerikId));
                Session.Add("SayfaGeri", "~/Forms/DersIcerikYoneticisi.aspx");
                Response.Redirect("~/Forms/DersIcerikGoruntule.aspx");
            }
        }


    }
}