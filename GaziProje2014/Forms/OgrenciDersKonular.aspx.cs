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
    public partial class OgrenciDersKonular : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
                GAZIEntities gaziEntities = new GAZIEntities();

                //** Öğrencinin daha önce seçtiği dersler
                var dersSecimListesi = (from oc in gaziEntities.OgrenciDersler
                                        join ot in gaziEntities.OgretmenDersler on oc.OgretmenDersId equals ot.OgretmenDersId
                                        join d in gaziEntities.Dersler on ot.DersId equals d.DersId
                                        where oc.UstOnay == true && oc.OgrenciId == kullaniciId
                                        select new { ot.OgretmenDersId, d.DersAdi }).ToList();

                rdcmbOgrenciOnayliDersler.DataSource = dersSecimListesi;
                rdcmbOgrenciOnayliDersler.DataTextField = "DersAdi";
                rdcmbOgrenciOnayliDersler.DataValueField = "OgretmenDersId";
                rdcmbOgrenciOnayliDersler.DataBind();

                //** Load Status
                if (Session["OgretmenDersId"] != null)
                {
                    rdcmbOgrenciOnayliDersler.SelectedValue = Session["OgretmenDersId"].ToString();
                }
                else
                {
                    Session.Add("OgretmenDersId", rdcmbOgrenciOnayliDersler.SelectedValue);
                }
                rdcmbOgrenciOnayliDersler_SelectedIndexChanged(null, null);

            }
        }

        protected void btnDersIcerikGoruntule_Click(object sender, EventArgs e)
        {
            if (dersIcerikTreeList.SelectedItems.Count > 0)
            {
                string icerikId = dersIcerikTreeList.SelectedItems[0].GetDataKeyValue("IcerikId").ToString();
                Session.Add("DersIcerikId", Convert.ToInt32(icerikId));
                Session.Add("SayfaGeri", "~/Forms/OgrenciDersKonular.aspx");
                Response.Redirect("~/Forms/DersIcerikGoruntule.aspx");
            }
        }

        protected void rdcmbOgrenciOnayliDersler_SelectedIndexChanged(object sender, RadComboBoxSelectedIndexChangedEventArgs e)
        {
            string ogretmenDersIdStr = rdcmbOgrenciOnayliDersler.SelectedValue;
            if (ogretmenDersIdStr != "")
            {
                int ogretmenDersId = Convert.ToInt32(ogretmenDersIdStr);

                GAZIEntities gaziEntities = new GAZIEntities();
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
            string ogretmenDersIdStr = rdcmbOgrenciOnayliDersler.SelectedValue;
            if (ogretmenDersIdStr != "")
            {
                int ogretmenDersId = Convert.ToInt32(ogretmenDersIdStr);

                GAZIEntities gaziEntities = new GAZIEntities();
                //** Konular Yukleniyor
                var konular = (from di in gaziEntities.DersIcerikler
                               where di.OgretmenDersId == ogretmenDersId
                               select new { di.IcerikId, di.IcerikPId, di.IcerikAdi, di.KayitTarihi, di.IconUrl }).Take(250).ToList();

                dersIcerikTreeList.DataSource = konular;
            }
        }

    }
}