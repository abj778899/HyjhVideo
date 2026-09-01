import Foundation
import WebKit
import Combine

class SourceCaptureViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    @Published var capturedSources: [VideoSource] = []
    @Published var isCapturing = false
    @Published var currentPageURL = ""
    @Published var pageTitle = ""
    @Published var showSourceList = false
    @Published var isLoading = false
    @Published var progress: Double = 0
    @Published var errorMessage: String?
    @Published var canGoBack = false
    @Published var canGoForward = false

    var webView: WKWebView?
    private var progressObserver: NSKeyValueObservation?
    private let homeURL = "https://m.hyjhzstj.com"

    // 去广告的域名列表
    private let adDomains = [
        "googlesyndication.com",
        "googleadservices.com",
        "doubleclick.net",
        "googletagmanager.com",
        "googletagservices.com",
        "google-analytics.com",
        "facebook.net",
        "fbcdn.net",
        "baidu.com",
        "bdstatic.com",
        "bdimg.com",
        "umeng.com",
        "umengcloud.com",
        "cnzz.com",
        "51.la",
        "qq.com",
        "gtimg.com",
        "alimama.com",
        "tanx.com",
        "mmstat.com",
        "adnxs.com",
        "advertising.com",
        "atdmt.com",
        "atwola.com",
        "yieldmanager.com",
        "scorecardresearch.com",
        "quantserve.com",
        "chartbeat.com",
        "chartbeat.net",
        "2mdn.net",
        "adbrite.com",
        "adsonar.com",
        "advertising.com",
        "apnxs.com",
        "atdmt.com",
        "atwola.com",
        "bluekai.com",
        "brilig.com",
        "contextweb.com",
        "doubleclick.com",
        "doubleclick.net",
        "falkag.net",
        "falkjs.net",
        "flickr.com",
        "googleadservices.com",
        "googlesyndication.com",
        "gravity.com",
        "imrworldwide.com",
        "invitemedia.com",
        "media6degrees.com",
        "mpstat.us",
        "nielsen-online.com",
        "omniture.com",
        "openx.net",
        "pagefair.com",
        "peer39.com",
        "pixel.quantserve.com",
        "pubmatic.com",
        "quantserve.com",
        "rkdms.com",
        "rubiconproject.com",
        "scorecardresearch.com",
        "serving-sys.com",
        "sharethrough.com",
        "sitescout.com",
        "smartadserver.com",
        "sonobi.com",
        "spotxchange.com",
        "spotx.tv",
        "tribalfusion.com",
        "turn.com",
        "unrulymedia.com",
        "videohub.tv",
        "vindicosuite.com",
        "yahoo.com",
        "yieldmanager.com",
        "zmags.com",
        "adservice.google.com",
        "pagead2.googlesyndication.com",
        "tpc.googlesyndication.com",
        "www.googleadservices.com",
        "www.googletagmanager.com",
        "www.google-analytics.com",
        "ssl.google-analytics.com",
        "stats.g.doubleclick.net",
        "www.facebook.com",
        "connect.facebook.net",
        "staticxx.facebook.com",
        "s.w.org",
        "wp.com",
        "pixel.wp.com",
        "stats.wp.com",
        "s0.wp.com",
        "s1.wp.com",
        "s2.wp.com",
        "i0.wp.com",
        "i1.wp.com",
        "i2.wp.com",
        "c0.wp.com",
        "widgets.wp.com",
        "r.ltrx.com",
        "l.bigmir.net",
        "tracker.qiwi.com",
        "ads.com",
        "ad.com",
        "adsrv.com",
        "adserver.com",
        "banner.com",
        "popads.net",
        "popcash.net",
        "propellerads.com",
        "propellerclick.com",
        "propellerads.io",
        "adsterra.com",
        "adsterra.org",
        "hilltopads.com",
        "exoclick.com",
        "juicyads.com",
        "trafficjunky.com",
        "trafficfactory.biz",
        "plugrush.com",
        "adskeeper.com",
        "adnow.com",
        "mgid.com",
        "content.ad",
        "revcontent.com",
        "outbrain.com",
        "taboola.com",
        "zergnet.com",
        "narrative.io",
        "ad.plus",
        "adskeeper.co.uk",
        "adspire.com",
        "adtng.com",
        "advertising.com",
        "affiliate.com",
        "agkn.com",
        "aquantive.com",
        "atdmt.com",
        "atwola.com",
        "b5m.com",
        "baidu.com",
        "bdstatic.com",
        "bebi.com",
        "betrad.com",
        "bidgear.com",
        "bluekai.com",
        "bm357.com",
        "boosj.com",
        "brave.com",
        "brilig.com",
        "burstly.com",
        "bxss.me",
        "c1exchange.com",
        "captcha.com",
        "cdnads.com",
        "centro.net",
        "cescomp.com",
        "chango.com",
        "clicksor.com",
        "cloudflare.com",
        "cnbeta.com",
        "cnzz.com",
        "cpxinteractive.com",
        "criteo.com",
        "crwdcntrl.net",
        "csgopolygon.com",
        "ctnet.com",
        "cyberconsole.com",
        "d1x5.com",
        "d2xw.com",
        "d3xq.com",
        "d4xr.com",
        "d5xt.com",
        "d6xu.com",
        "d7xv.com",
        "d8xw.com",
        "d9xx.com",
        "daxw.com",
        "dbxw.com",
        "dcxw.com",
        "ddxw.com",
        "dexw.com",
        "dfxw.com",
        "dgxw.com",
        "dhxw.com",
        "dixw.com",
        "djxw.com",
        "dkxw.com",
        "dlxw.com",
        "dmxw.com",
        "dnxw.com",
        "doxw.com",
        "dpxw.com",
        "dqxw.com",
        "drxw.com",
        "dsxw.com",
        "dtxw.com",
        "duxw.com",
        "dvxw.com",
        "dwxw.com",
        "dxxw.com",
        "dyxw.com",
        "dzxw.com",
        "eadv.com",
        "ebay.com",
        "edgecast.com",
        "eliquid.com",
        "emxdgt.com",
        "engageya.com",
        "epom.com",
        "eroterest.com",
        "exosrv.com",
        "facebook.com",
        "fastclick.com",
        "favicon.com",
        "feedjit.com",
        "felm.com",
        "fwmrm.net",
        "game-ad.com",
        "gameads.com",
        "gammaplatform.com",
        "google.com",
        "gstatic.com",
        "gumgum.com",
        "hulu.com",
        "id5-sync.com",
        "imonomy.com",
        "innity.com",
        "intergi.com",
        "invitemedia.com",
        "ipredictive.com",
        "jads.co",
        "jquery.com",
        "jwplayer.com",
        "jwplatform.com",
        "kargo.com",
        "kissmetrics.com",
        "krxd.net",
        "lendingtree.com",
        "livejasmin.com",
        "liveperson.com",
        "liverail.com",
        "lockerdome.com",
        "lognormal.com",
        "luminate.com",
        "m1m.com",
        "marfeel.com",
        "mathtag.com",
        "media.net",
        "media6degrees.com",
        "megaclick.com",
        "moatads.com",
        "mobfox.com",
        "moceanad.com",
        "mopub.com",
        "myvisualiq.net",
        "narrative.io",
        "nativo.com",
        "navdmp.com",
        "nend.net",
        "netseer.com",
        "neustar.biz",
        "neworlive.com",
        "noddus.com",
        "noise.agency",
        "nuggad.net",
        "nytimes.com",
        "oewabox.com",
        "oewa.at",
        "oewa24.at",
        "omtrdc.net",
        "onetag.com",
        "openx.net",
        "optnmnstr.com",
        "oracle.com",
        "outbrain.com",
        "owneriq.net",
        "p.jwpcdn.com",
        "p161.info",
        "p2l.info",
        "pagefair.com",
        "paloaltonetworks.com",
        "parsely.com",
        "pbs.twimg.com",
        "pcapredict.com",
        "permutive.com",
        "phn1.net",
        "phn2.net",
        "pippio.com",
        "pixfuture.com",
        "piximedia.com",
        "playwire.com",
        "plista.com",
        "plusone.google.com",
        "pocketfives.com",
        "polarmobile.com",
        "popcash.net",
        "popads.net",
        "popin.cc",
        "popmyads.com",
        "popns.com",
        "po.st",
        "prebid.org",
        "primis.tech",
        "privacymanager.io",
        "proclivity.net",
        "propellerads.com",
        "pubmatic.com",
        "pubmine.com",
        "pulsepoint.com",
        "purch.com",
        "quantcast.com",
        "quantserve.com",
        "qualaroo.com",
        "qwilr.com",
        "r6.me",
        "r7.com",
        "rakuten.com",
        "rcvdk.com",
        "realclick.com",
        "realmedia.com",
        "recomendo.com",
        "reddit.com",
        "redtram.com",
        "refinery89.com",
        "relap.io",
        "reporo.com",
        "resolve.speedbit.com",
        "responsetap.com",
        "revcontent.com",
        "richaudience.com",
        "rkdms.com",
        "robertoverflow.com",
        "rocket-loader.com",
        "rolex.com",
        "rubiconproject.com",
        "s468x60.com",
        "safeframe.googlesyndication.com",
        "samsungads.com",
        "sascdn.com",
        "scorecardresearch.com",
        "sekindo.com",
        "serving-sys.com",
        "sharethrough.com",
        "shopping.com",
        "simpli.fi",
        "sitechecker.com",
        "sitescout.com",
        "skimresources.com",
        "smartadserver.com",
        "smartyads.com",
        "smilewanted.com",
        "snap.com",
        "snatam.com",
        "social9.com",
        "sociaplus.com",
        "sonobi.com",
        "soo.gd",
        "sovrn.com",
        "sp1.nypost.com",
        "speakerspot.com",
        "spot.im",
        "spotxchange.com",
        "spotx.tv",
        "springserve.com",
        "sprtas.com",
        "ssp.ynet.co.il",
        "stickyadstv.com",
        "stocktwits.com",
        "streampixel.net",
        "stumbleupon.com",
        "sumome.com",
        "sundx.com",
        "survata.com",
        "svpply.com",
        "swissadmedia.com",
        "taboola.com",
        "tagnum.com",
        "tapad.com",
        "tastynetwork.com",
        "tbs.com",
        "technorati.com",
        "teads.com",
        "teads.tv",
        "telemetrydeck.com",
        "temptation.com",
        "theadvocate.com",
        "theatlantic.com",
        "thedailybeast.com",
        "thefancy.com",
        "theguardian.com",
        "thehill.com",
        "thehollywoodgossip.com",
        "thenews.com",
        "thenytimes.com",
        "theonion.com",
        "thestar.com",
        "thesun.co.uk",
        "thethirty.com",
        "theverge.com",
        "theweek.com",
        "thinkcreative.com",
        "thriveglobal.com",
        "tiktok.com",
        "time.com",
        "timesofindia.com",
        "tinypass.com",
        "tipr.com",
        "tmall.com",
        "todocount.com",
        "top10.com",
        "toplist.com",
        "torrentfreak.com",
        "total-ads.com",
        "toutiao.com",
        "traffic.com",
        "trafficjunky.com",
        "trafficfactory.biz",
        "traffective.com",
        "tremorhub.com",
        "trendmicro.com",
        "triplelift.com",
        "truste.com",
        "trustx.org",
        "try.abtasty.com",
        "tubemogul.com",
        "tumblr.com",
        "tune.com",
        "twitch.tv",
        "twitter.com",
        "typekit.com",
        "tynt.com",
        "uber.com",
        "ucoz.com",
        "uimserv.net",
        "um-public-panel-prod.s3.amazonaws.com",
        "unrulymedia.com",
        "upworthy.com",
        "urbanairship.com",
        "usabilla.com",
        "userneeds.com",
        "ustream.tv",
        "v12group.com",
        "valuecommerce.com",
        "vdopia.com",
        "veeseo.com",
        "velen.io",
        "ventuno.com",
        "verizon.com",
        "verizonmedia.com",
        "verycloud.cn",
        "vimeo.com",
        "vindicosuite.com",
        "vio.com",
        "visilabs.com",
        "visualwebsiteoptimizer.com",
        "vkontakte.ru",
        "vungle.com",
        "w55c.net",
        "wallstreetonline.com",
        "washingtonpost.com",
        "watchlistmedia.com",
        "weborama.net",
        "webengage.com",
        "webmasterplan.com",
        "weborama.fr",
        "wechat.com",
        "weibo.com",
        "wikipedia.org",
        "wired.com",
        "wish.com",
        "wittyfeed.com",
        "wmp.it",
        "wpnrtn.com",
        "wsj.com",
        "wtforms.com",
        "wunderground.com",
        "wyzant.com",
        "xaxis.com",
        "xbox.com",
        "xhamster.com",
        "xfinity.com",
        "xing.com",
        "xl.co",
        "xlog.snssdk.com",
        "xn--3px457fva.com",
        "xplus.com",
        "xq1.com",
        "xfinity.comcast.net",
        "yahoo.com",
        "yandex.com",
        "yandex.ru",
        "ybrant.com",
        "yieldbot.com",
        "yieldlab.net",
        "yieldmo.com",
        "yieldoptimizer.com",
        "yieldpro.com",
        "yimg.com",
        "yoox.com",
        "youtube.com",
        "ytimg.com",
        "yumenetworks.com",
        "zedo.com",
        "zeglo.com",
        "zemanta.com",
        "zhihu.com",
        "ziffdavis.com",
        "zillow.com",
        "zingfront.com",
        "zloads.com",
        "zmags.com",
        "zomato.com",
        "zoom.com",
        "zopim.com",
        "zuora.com",
        "zynga.com"
    ]

    func setupWebView(_ webView: WKWebView) {
        self.webView = webView
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = false

        // 注入JS拦截网络请求
        injectCaptureScript()

        // 注入去广告JS
        injectAdBlockScript()

        progressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, value in
            DispatchQueue.main.async {
                self?.progress = value.newValue ?? 0
            }
        }
    }

    private func injectCaptureScript() {
        guard let webView = webView else { return }

        let jsCode = """
        (function() {
            const capturedSources = [];
            const videoExtensions = ['.m3u8', '.mp4', '.m4v', '.mov', '.ts', '.flv', '.webm', '.avi', '.mkv'];
            const videoPatterns = [/\\.m3u8(\\?|$)/i, /\\.mp4(\\?|$)/i, /\\.m4v(\\?|$)/i, /\\.mov(\\?|$)/i, /\\.ts(\\?|$)/i, /\\.flv(\\?|$)/i, /\\.webm(\\?|$)/i, /m3u8/i, /mp4/i, /flv/i, /video/i, /play/i, /stream/i, /live/i];

            function isVideoURL(url) {
                if (!url) return false;
                const lowerUrl = url.toLowerCase();
                for (const ext of videoExtensions) {
                    if (lowerUrl.includes(ext)) return true;
                }
                for (const pattern of videoPatterns) {
                    if (pattern.test(url)) return true;
                }
                return false;
            }

            function getVideoType(url) {
                const lowerUrl = url.toLowerCase();
                if (lowerUrl.includes('.m3u8') || lowerUrl.includes('m3u8')) return 'm3u8';
                if (lowerUrl.includes('.mp4') || lowerUrl.includes('mp4')) return 'mp4';
                if (lowerUrl.includes('.flv') || lowerUrl.includes('flv')) return 'flv';
                if (lowerUrl.includes('.m4v') || lowerUrl.includes('m4v')) return 'm4v';
                if (lowerUrl.includes('.mov') || lowerUrl.includes('mov')) return 'mov';
                if (lowerUrl.includes('.ts') || lowerUrl.includes('ts')) return 'ts';
                if (lowerUrl.includes('.webm') || lowerUrl.includes('webm')) return 'webm';
                return 'unknown';
            }

            function getQuality(url) {
                const lowerUrl = url.toLowerCase();
                if (lowerUrl.includes('1080') || lowerUrl.includes('fhd') || lowerUrl.includes('1080p')) return '1080P';
                if (lowerUrl.includes('720') || lowerUrl.includes('hd') || lowerUrl.includes('720p')) return '720P';
                if (lowerUrl.includes('480') || lowerUrl.includes('sd') || lowerUrl.includes('480p')) return '480P';
                if (lowerUrl.includes('360') || lowerUrl.includes('ld') || lowerUrl.includes('360p')) return '360P';
                if (lowerUrl.includes('240') || lowerUrl.includes('240p')) return '240P';
                return null;
            }

            function captureSource(url, title) {
                if (!url || !isVideoURL(url)) return;
                const source = {
                    url: url,
                    type: getVideoType(url),
                    quality: getQuality(url),
                    title: title || document.title || '未命名视频',
                    pageURL: window.location.href,
                    capturedAt: new Date().toISOString()
                };
                const exists = capturedSources.some(s => s.url === url);
                if (!exists) {
                    capturedSources.push(source);
                    window.webkit.messageHandlers.videoSourceCaptured.postMessage(source);
                }
            }

            // 拦截XMLHttpRequest
            const originalXHR = window.XMLHttpRequest;
            function CustomXHR() {
                const xhr = new originalXHR();
                const originalOpen = xhr.open;
                xhr.open = function(method, url) {
                    captureSource(url);
                    return originalOpen.apply(this, arguments);
                };
                return xhr;
            }
            CustomXHR.prototype = originalXHR.prototype;
            window.XMLHttpRequest = CustomXHR;

            // 拦截fetch
            const originalFetch = window.fetch;
            window.fetch = function(input, init) {
                let url = '';
                if (typeof input === 'string') {
                    url = input;
                } else if (input && input.url) {
                    url = input.url;
                }
                captureSource(url);
                return originalFetch.apply(this, arguments);
            };

            // 拦截video标签的src
            function observeVideos() {
                const videos = document.querySelectorAll('video');
                videos.forEach(video => {
                    if (video.src) {
                        captureSource(video.src, video.title || document.title);
                    }
                    if (video.currentSrc) {
                        captureSource(video.currentSrc, video.title || document.title);
                    }
                    const sources = video.querySelectorAll('source');
                    sources.forEach(source => {
                        if (source.src) {
                            captureSource(source.src, video.title || document.title);
                        }
                    });
                });
            }

            // 监听DOM变化
            const observer = new MutationObserver(() => {
                observeVideos();
            });
            observer.observe(document.body, { childList: true, subtree: true });

            // 定期检查
            setInterval(observeVideos, 2000);

            // 初始检查
            setTimeout(observeVideos, 1000);

            // 暴露获取所有捕获源的方法
            window.getCapturedSources = function() {
                return capturedSources;
            };

            // 暴露清空捕获源的方法
            window.clearCapturedSources = function() {
                capturedSources.length = 0;
            };

            console.log('Video source capture script injected');
        })();
        """

        let userScript: WKUserScript!
        if #available(iOS 14.0, *) {
            userScript = WKUserScript(source: jsCode, injectionTime: .atDocumentStart, forMainFrameOnly: false, in: .defaultClient)
        } else {
            userScript = WKUserScript(source: jsCode, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        }
        webView.configuration.userContentController.addUserScript(userScript)
        webView.configuration.userContentController.add(self, name: "videoSourceCaptured")
    }

    private func injectAdBlockScript() {
        guard let webView = webView else { return }

        let jsCode = """
        (function() {
            // 常见广告选择器
            const adSelectors = [
                '[id*="ad"]',
                '[class*="ad"]',
                '[id*="AD"]',
                '[class*="AD"]',
                '[id*="Ad"]',
                '[class*="Ad"]',
                '[id*="advert"]',
                '[class*="advert"]',
                '[id*="banner"]',
                '[class*="banner"]',
                '[id*="popup"]',
                '[class*="popup"]',
                '[id*="pop-up"]',
                '[class*="pop-up"]',
                '[id*="popunder"]',
                '[class*="popunder"]',
                '[id*="float"]',
                '[class*="float"]',
                '[id*="floating"]',
                '[class*="floating"]',
                '[id*="fixed"]',
                '[class*="fixed"]',
                '[id*="overlay"]',
                '[class*="overlay"]',
                '[id*="modal"]',
                '[class*="modal"]',
                '[id*="dialog"]',
                '[class*="dialog"]',
                '[id*="promo"]',
                '[class*="promo"]',
                '[id*="promotion"]',
                '[class*="promotion"]',
                '[id*="sponsor"]',
                '[class*="sponsor"]',
                '[id*="sponsored"]',
                '[class*="sponsored"]',
                '[id*="partner"]',
                '[class*="partner"]',
                '[id*="affiliate"]',
                '[class*="affiliate"]',
                '[id*="tracking"]',
                '[class*="tracking"]',
                '[id*="tracker"]',
                '[class*="tracker"]',
                '[id*="analytics"]',
                '[class*="analytics"]',
                '[id*="stat"]',
                '[class*="stat"]',
                '[id*="counter"]',
                '[class*="counter"]',
                '[id*="pixel"]',
                '[class*="pixel"]',
                '[id*="beacon"]',
                '[class*="beacon"]',
                '[id*="tag"]',
                '[class*="tag"]',
                '[id*="gtm"]',
                '[class*="gtm"]',
                '[id*="ga"]',
                '[class*="ga"]',
                '[id*="fb"]',
                '[class*="fb"]',
                '[id*="baidu"]',
                '[class*="baidu"]',
                '[id*="cnzz"]',
                '[class*="cnzz"]',
                '[id*="umeng"]',
                '[class*="umeng"]',
                '[id*="51la"]',
                '[class*="51la"]',
                '[id*="51.la"]',
                '[class*="51.la"]',
                'iframe[src*="ad"]',
                'iframe[src*="banner"]',
                'iframe[src*="popup"]',
                'iframe[src*="advert"]',
                'iframe[src*="googleads"]',
                'iframe[src*="googlesyndication"]',
                'iframe[src*="doubleclick"]',
                'iframe[src*="facebook"]',
                'iframe[src*="baidu"]',
                'ins.adsbygoogle',
                'div[class*="adsbygoogle"]',
                'div[id*="adsbygoogle"]',
                'div[class*="google-auto-placed"]',
                'div[id*="google_auto_placed"]',
                'div[class*="google_ads"]',
                'div[id*="google_ads"]',
                'div[class*="google-ad"]',
                'div[id*="google-ad"]',
                'div[class*="gpt-ad"]',
                'div[id*="gpt-ad"]',
                'div[class*="gpt_ad"]',
                'div[id*="gpt_ad"]',
                'div[class*="ad-slot"]',
                'div[id*="ad-slot"]',
                'div[class*="ad_slot"]',
                'div[id*="ad_slot"]',
                'div[class*="ad-wrapper"]',
                'div[id*="ad-wrapper"]',
                'div[class*="ad_wrapper"]',
                'div[id*="ad_wrapper"]',
                'div[class*="ad-container"]',
                'div[id*="ad-container"]',
                'div[class*="ad_container"]',
                'div[id*="ad_container"]',
                'div[class*="ad-placeholder"]',
                'div[id*="ad-placeholder"]',
                'div[class*="ad_placeholder"]',
                'div[id*="ad_placeholder"]',
                'div[class*="ad-banner"]',
                'div[id*="ad-banner"]',
                'div[class*="ad_banner"]',
                'div[id*="ad_banner"]',
                'div[class*="ad-leaderboard"]',
                'div[id*="ad-leaderboard"]',
                'div[class*="ad_leaderboard"]',
                'div[id*="ad_leaderboard"]',
                'div[class*="ad-skyscraper"]',
                'div[id*="ad-skyscraper"]',
                'div[class*="ad_skyscraper"]',
                'div[id*="ad_skyscraper"]',
                'div[class*="ad-rectangle"]',
                'div[id*="ad-rectangle"]',
                'div[class*="ad_rectangle"]',
                'div[id*="ad_rectangle"]',
                'div[class*="ad-square"]',
                'div[id*="ad-square"]',
                'div[class*="ad_square"]',
                'div[id*="ad_square"]',
                'div[class*="ad-button"]',
                'div[id*="ad-button"]',
                'div[class*="ad_button"]',
                'div[id*="ad_button"]',
                'div[class*="ad-link"]',
                'div[id*="ad-link"]',
                'div[class*="ad_link"]',
                'div[id*="ad_link"]',
                'div[class*="ad-image"]',
                'div[id*="ad-image"]',
                'div[class*="ad_image"]',
                'div[id*="ad_image"]',
                'div[class*="ad-video"]',
                'div[id*="ad-video"]',
                'div[class*="ad_video"]',
                'div[id*="ad_video"]',
                'div[class*="ad-text"]',
                'div[id*="ad-text"]',
                'div[class*="ad_text"]',
                'div[id*="ad_text"]',
                'div[class*="ad-title"]',
                'div[id*="ad-title"]',
                'div[class*="ad_title"]',
                'div[id*="ad_title"]',
                'div[class*="ad-description"]',
                'div[id*="ad-description"]',
                'div[class*="ad_description"]',
                'div[id*="ad_description"]',
                'div[class*="ad-footer"]',
                'div[id*="ad-footer"]',
                'div[class*="ad_footer"]',
                'div[id*="ad_footer"]',
                'div[class*="ad-header"]',
                'div[id*="ad-header"]',
                'div[class*="ad_header"]',
                'div[id*="ad_header"]',
                'div[class*="ad-sidebar"]',
                'div[id*="ad-sidebar"]',
                'div[class*="ad_sidebar"]',
                'div[id*="ad_sidebar"]',
                'div[class*="ad-top"]',
                'div[id*="ad-top"]',
                'div[class*="ad_top"]',
                'div[id*="ad_top"]',
                'div[class*="ad-bottom"]',
                'div[id*="ad-bottom"]',
                'div[class*="ad_bottom"]',
                'div[id*="ad_bottom"]',
                'div[class*="ad-left"]',
                'div[id*="ad-left"]',
                'div[class*="ad_left"]',
                'div[id*="ad_left"]',
                'div[class*="ad-right"]',
                'div[id*="ad-right"]',
                'div[class*="ad_right"]',
                'div[id*="ad_right"]',
                'div[class*="ad-center"]',
                'div[id*="ad-center"]',
                'div[class*="ad_center"]',
                'div[id*="ad_center"]',
                'div[class*="ad-middle"]',
                'div[id*="ad-middle"]',
                'div[class*="ad_middle"]',
                'div[id*="ad_middle"]',
                'div[class*="ad-inner"]',
                'div[id*="ad-inner"]',
                'div[class*="ad_inner"]',
                'div[id*="ad_inner"]',
                'div[class*="ad-outer"]',
                'div[id*="ad-outer"]',
                'div[class*="ad_outer"]',
                'div[id*="ad_outer"]',
                'div[class*="ad-main"]',
                'div[id*="ad-main"]',
                'div[class*="ad_main"]',
                'div[id*="ad_main"]',
                'div[class*="ad-sub"]',
                'div[id*="ad-sub"]',
                'div[class*="ad_sub"]',
                'div[id*="ad_sub"]',
                'div[class*="ad-item"]',
                'div[id*="ad-item"]',
                'div[class*="ad_item"]',
                'div[id*="ad_item"]',
                'div[class*="ad-list"]',
                'div[id*="ad-list"]',
                'div[class*="ad_list"]',
                'div[id*="ad_list"]',
                'div[class*="ad-grid"]',
                'div[id*="ad-grid"]',
                'div[class*="ad_grid"]',
                'div[id*="ad_grid"]',
                'div[class*="ad-row"]',
                'div[id*="ad-row"]',
                'div[class*="ad_row"]',
                'div[id*="ad_row"]',
                'div[class*="ad-col"]',
                'div[id*="ad-col"]',
                'div[class*="ad_col"]',
                'div[id*="ad_col"]',
                'div[class*="ad-box"]',
                'div[id*="ad-box"]',
                'div[class*="ad_box"]',
                'div[id*="ad_box"]',
                'div[class*="ad-block"]',
                'div[id*="ad-block"]',
                'div[class*="ad_block"]',
                'div[id*="ad_block"]',
                'div[class*="ad-section"]',
                'div[id*="ad-section"]',
                'div[class*="ad_section"]',
                'div[id*="ad_section"]',
                'div[class*="ad-area"]',
                'div[id*="ad-area"]',
                'div[class*="ad_area"]',
                'div[id*="ad_area"]',
                'div[class*="ad-zone"]',
                'div[id*="ad-zone"]',
                'div[class*="ad_zone"]',
                'div[id*="ad_zone"]',
                'div[class*="ad-space"]',
                'div[id*="ad-space"]',
                'div[class*="ad_space"]',
                'div[id*="ad_space"]',
                'div[class*="ad-spot"]',
                'div[id*="ad-spot"]',
                'div[class*="ad_spot"]',
                'div[id*="ad_spot"]',
                'div[class*="ad-unit"]',
                'div[id*="ad-unit"]',
                'div[class*="ad_unit"]',
                'div[id*="ad_unit"]',
                'div[class*="ad-tag"]',
                'div[id*="ad-tag"]',
                'div[class*="ad_tag"]',
                'div[id*="ad_tag"]',
                'div[class*="ad-label"]',
                'div[id*="ad-label"]',
                'div[class*="ad_label"]',
                'div[id*="ad_label"]',
                'div[class*="ad-badge"]',
                'div[id*="ad-badge"]',
                'div[class*="ad_badge"]',
                'div[id*="ad_badge"]',
                'div[class*="ad-icon"]',
                'div[id*="ad-icon"]',
                'div[class*="ad_icon"]',
                'div[id*="ad_icon"]',
                'div[class*="ad-logo"]',
                'div[id*="ad-logo"]',
                'div[class*="ad_logo"]',
                'div[id*="ad_logo"]',
                'div[class*="ad-brand"]',
                'div[id*="ad-brand"]',
                'div[class*="ad_brand"]',
                'div[id*="ad_brand"]',
                'div[class*="ad-sponsor"]',
                'div[id*="ad-sponsor"]',
                'div[class*="ad_sponsor"]',
                'div[id*="ad_sponsor"]',
                'div[class*="ad-partner"]',
                'div[id*="ad-partner"]',
                'div[class*="ad_partner"]',
                'div[id*="ad_partner"]',
                'div[class*="ad-affiliate"]',
                'div[id*="ad-affiliate"]',
                'div[class*="ad_affiliate"]',
                'div[id*="ad_affiliate"]',
                'div[class*="ad-promo"]',
                'div[id*="ad-promo"]',
                'div[class*="ad_promo"]',
                'div[id*="ad_promo"]',
                'div[class*="ad-promotion"]',
                'div[id*="ad-promotion"]',
                'div[class*="ad_promotion"]',
                'div[id*="ad_promotion"]',
                'div[class*="ad-offer"]',
                'div[id*="ad-offer"]',
                'div[class*="ad_offer"]',
                'div[id*="ad_offer"]',
                'div[class*="ad-deal"]',
                'div[id*="ad-deal"]',
                'div[class*="ad_deal"]',
                'div[id*="ad_deal"]',
                'div[class*="ad-discount"]',
                'div[id*="ad-discount"]',
                'div[class*="ad_discount"]',
                'div[id*="ad_discount"]',
                'div[class*="ad-sale"]',
                'div[id*="ad-sale"]',
                'div[class*="ad_sale"]',
                'div[id*="ad_sale"]',
                'div[class*="ad-shop"]',
                'div[id*="ad-shop"]',
                'div[class*="ad_shop"]',
                'div[id*="ad_shop"]',
                'div[class*="ad-store"]',
                'div[id*="ad-store"]',
                'div[class*="ad_store"]',
                'div[id*="ad_store"]',
                'div[class*="ad-buy"]',
                'div[id*="ad-buy"]',
                'div[class*="ad_buy"]',
                'div[id*="ad_buy"]',
                'div[class*="ad-cart"]',
                'div[id*="ad-cart"]',
                'div[class*="ad_cart"]',
                'div[id*="ad_cart"]',
                'div[class*="ad-checkout"]',
                'div[id*="ad-checkout"]',
                'div[class*="ad_checkout"]',
                'div[id*="ad_checkout"]',
                'div[class*="ad-payment"]',
                'div[id*="ad-payment"]',
                'div[class*="ad_payment"]',
                'div[id*="ad_payment"]',
                'div[class*="ad-subscribe"]',
                'div[id*="ad-subscribe"]',
                'div[class*="ad_subscribe"]',
                'div[id*="ad_subscribe"]',
                'div[class*="ad-signup"]',
                'div[id*="ad-signup"]',
                'div[class*="ad_signup"]',
                'div[id*="ad_signup"]',
                'div[class*="ad-register"]',
                'div[id*="ad-register"]',
                'div[class*="ad_register"]',
                'div[id*="ad_register"]',
                'div[class*="ad-login"]',
                'div[id*="ad-login"]',
                'div[class*="ad_login"]',
                'div[id*="ad_login"]',
                'div[class*="ad-download"]',
                'div[id*="ad-download"]',
                'div[class*="ad_download"]',
                'div[id*="ad_download"]',
                'div[class*="ad-install"]',
                'div[id*="ad-install"]',
                'div[class*="ad_install"]',
                'div[id*="ad_install"]',
                'div[class*="ad-app"]',
                'div[id*="ad-app"]',
                'div[class*="ad_app"]',
                'div[id*="ad_app"]',
                'div[class*="ad-game"]',
                'div[id*="ad-game"]',
                'div[class*="ad_game"]',
                'div[id*="ad_game"]',
                'div[class*="ad-video-ad"]',
                'div[id*="ad-video-ad"]',
                'div[class*="ad_video_ad"]',
                'div[id*="ad_video_ad"]',
                'div[class*="ad-preroll"]',
                'div[id*="ad-preroll"]',
                'div[class*="ad_preroll"]',
                'div[id*="ad_preroll"]',
                'div[class*="ad-midroll"]',
                'div[id*="ad-midroll"]',
                'div[class*="ad_midroll"]',
                'div[id*="ad_midroll"]',
                'div[class*="ad-postroll"]',
                'div[id*="ad-postroll"]',
                'div[class*="ad_postroll"]',
                'div[id*="ad_postroll"]',
                'div[class*="ad-overlay-ad"]',
                'div[id*="ad-overlay-ad"]',
                'div[class*="ad_overlay_ad"]',
                'div[id*="ad_overlay_ad"]',
                'div[class*="ad-skippable"]',
                'div[id*="ad-skippable"]',
                'div[class*="ad_skippable"]',
                'div[id*="ad_skippable"]',
                'div[class*="ad-non-skippable"]',
                'div[id*="ad-non-skippable"]',
                'div[class*="ad_non_skippable"]',
                'div[id*="ad_non_skippable"]',
                'div[class*="ad-countdown"]',
                'div[id*="ad-countdown"]',
                'div[class*="ad_countdown"]',
                'div[id*="ad_countdown"]',
                'div[class*="ad-skip"]',
                'div[id*="ad-skip"]',
                'div[class*="ad_skip"]',
                'div[id*="ad_skip"]',
                'div[class*="ad-skip-button"]',
                'div[id*="ad-skip-button"]',
                'div[class*="ad_skip_button"]',
                'div[id*="ad_skip_button"]',
                'div[class*="ad-learn-more"]',
                'div[id*="ad-learn-more"]',
                'div[class*="ad_learn_more"]',
                'div[id*="ad_learn_more"]',
                'div[class*="ad-visit"]',
                'div[id*="ad-visit"]',
                'div[class*="ad_visit"]',
                'div[id*="ad_visit"]',
                'div[class*="ad-website"]',
                'div[id*="ad-website"]',
                'div[class*="ad_website"]',
                'div[id*="ad_website"]',
                'div[class*="ad-link-out"]',
                'div[id*="ad-link-out"]',
                'div[class*="ad_link_out"]',
                'div[id*="ad_link_out"]',
                'div[class*="ad-external"]',
                'div[id*="ad-external"]',
                'div[class*="ad_external"]',
                'div[id*="ad_external"]',
                'div[class*="ad-cta"]',
                'div[id*="ad-cta"]',
                'div[class*="ad_cta"]',
                'div[id*="ad_cta"]',
                'div[class*="ad-call-to-action"]',
                'div[id*="ad-call-to-action"]',
                'div[class*="ad_call_to_action"]',
                'div[id*="ad_call_to_action"]',
                'div[class*="ad-button-primary"]',
                'div[id*="ad-button-primary"]',
                'div[class*="ad_button_primary"]',
                'div[id*="ad_button_primary"]',
                'div[class*="ad-button-secondary"]',
                'div[id*="ad-button-secondary"]',
                'div[class*="ad_button_secondary"]',
                'div[id*="ad_button_secondary"]',
                'div[class*="ad-close"]',
                'div[id*="ad-close"]',
                'div[class*="ad_close"]',
                'div[id*="ad_close"]',
                'div[class*="ad-close-button"]',
                'div[id*="ad-close-button"]',
                'div[class*="ad_close_button"]',
                'div[id*="ad_close_button"]',
                'div[class*="ad-dismiss"]',
                'div[id*="ad-dismiss"]',
                'div[class*="ad_dismiss"]',
                'div[id*="ad_dismiss"]',
                'div[class*="ad-dismiss-button"]',
                'div[id*="ad-dismiss-button"]',
                'div[class*="ad_dismiss_button"]',
                'div[id*="ad_dismiss_button"]',
                'div[class*="ad-hide"]',
                'div[id*="ad-hide"]',
                'div[class*="ad_hide"]',
                'div[id*="ad_hide"]',
                'div[class*="ad-hide-button"]',
                'div[id*="ad-hide-button"]',
                'div[class*="ad_hide_button"]',
                'div[id*="ad_hide_button"]',
                'div[class*="ad-remove"]',
                'div[id*="ad-remove"]',
                'div[class*="ad_remove"]',
                'div[id*="ad_remove"]',
                'div[class*="ad-remove-button"]',
                'div[id*="ad-remove-button"]',
                'div[class*="ad_remove_button"]',
                'div[id*="ad_remove_button"]',
                'div[class*="ad-x"]',
                'div[id*="ad-x"]',
                'div[class*="ad_x"]',
                'div[id*="ad_x"]',
                'div[class*="ad-x-button"]',
                'div[id*="ad-x-button"]',
                'div[class*="ad_x_button"]',
                'div[id*="ad_x_button"]',
                'div[class*="ad-times"]',
                'div[id*="ad-times"]',
                'div[class*="ad_times"]',
                'div[id*="ad_times"]',
                'div[class*="ad-times-button"]',
                'div[id*="ad-times-button"]',
                'div[class*="ad_times_button"]',
                'div[id*="ad_times_button"]'
            ];

            function removeAds() {
                adSelectors.forEach(selector => {
                    try {
                        const elements = document.querySelectorAll(selector);
                        elements.forEach(el => {
                            // 确保不是视频播放器
                            if (el.tagName === 'VIDEO' || el.querySelector('video')) {
                                return;
                            }
                            // 确保不是主要内容区域
                            if (el.id === 'content' || el.id === 'main' || el.id === 'player' || el.id === 'video') {
                                return;
                            }
                            // 移除元素
                            if (el.parentNode) {
                                el.parentNode.removeChild(el);
                            } else {
                                el.style.display = 'none';
                                el.style.visibility = 'hidden';
                                el.style.opacity = '0';
                                el.style.width = '0';
                                el.style.height = '0';
                                el.style.overflow = 'hidden';
                            }
                        });
                    } catch(e) {}
                });

                // 移除固定定位的广告弹窗
                const fixedElements = document.querySelectorAll('div[style*="position: fixed"], div[style*="position:fixed"], div[style*="position: absolute"], div[style*="position:absolute"]');
                fixedElements.forEach(el => {
                    const rect = el.getBoundingClientRect();
                    // 如果是小尺寸的固定元素，可能是广告
                    if (rect.width > 0 && rect.width < window.innerWidth * 0.8 && 
                        rect.height > 0 && rect.height < window.innerHeight * 0.8 &&
                        rect.width > 50 && rect.height > 50) {
                        // 检查是否包含关闭按钮
                        const closeBtn = el.querySelector('[class*="close"], [id*="close"], [class*="x"], [id*="x"], [class*="dismiss"], [id*="dismiss"]');
                        if (closeBtn) {
                            if (el.parentNode) {
                                el.parentNode.removeChild(el);
                            }
                        }
                    }
                });

                // 移除iframe广告
                const iframes = document.querySelectorAll('iframe');
                iframes.forEach(iframe => {
                    const src = iframe.src || '';
                    const isAd = adDomains.some(domain => src.includes(domain));
                    if (isAd) {
                        if (iframe.parentNode) {
                            iframe.parentNode.removeChild(iframe);
                        }
                    }
                });

                // 移除script广告
                const scripts = document.querySelectorAll('script[src]');
                scripts.forEach(script => {
                    const src = script.src || '';
                    const isAd = adDomains.some(domain => src.includes(domain));
                    if (isAd) {
                        if (script.parentNode) {
                            script.parentNode.removeChild(script);
                        }
                    }
                });

                // 移除img广告
                const images = document.querySelectorAll('img[src]');
                images.forEach(img => {
                    const src = img.src || '';
                    const isAd = adDomains.some(domain => src.includes(domain));
                    if (isAd) {
                        if (img.parentNode) {
                            img.parentNode.removeChild(img);
                        }
                    }
                });

                // 跳过视频广告
                const videos = document.querySelectorAll('video');
                videos.forEach(video => {
                    // 检查是否是广告视频
                    const isAd = video.className.includes('ad') || video.id.includes('ad') || 
                                 video.parentElement?.className.includes('ad') || 
                                 video.parentElement?.id.includes('ad');
                    if (isAd) {
                        // 静音并快进
                        video.muted = true;
                        if (video.duration && video.duration < 60) {
                            video.currentTime = video.duration;
                        }
                        // 尝试暂停
                        video.pause();
                        // 隐藏
                        video.style.display = 'none';
                    }
                });

                // 自动点击跳过广告按钮
                const skipButtons = document.querySelectorAll('[class*="skip"], [id*="skip"], [class*="Skip"], [id*="Skip"], [class*="SKIP"], [id*="SKIP"]');
                skipButtons.forEach(btn => {
                    if (btn.offsetParent !== null) { // 可见
                        btn.click();
                    }
                });

                // 自动点击关闭按钮
                const closeButtons = document.querySelectorAll('[class*="close"], [id*="close"], [class*="Close"], [id*="Close"], [class*="CLOSE"], [id*="CLOSE"], [class*="dismiss"], [id*="dismiss"], [class*="x"], [id*="x"], [class*="X"], [id*="X"]');
                closeButtons.forEach(btn => {
                    if (btn.offsetParent !== null && btn.tagName !== 'VIDEO') {
                        const rect = btn.getBoundingClientRect();
                        if (rect.width < 100 && rect.height < 100) { // 小按钮
                            // 不自动点击，避免误操作
                        }
                    }
                });

                console.log('Ads removed');
            }

            // 监听DOM变化
            const observer = new MutationObserver(() => {
                removeAds();
            });
            observer.observe(document.body, { childList: true, subtree: true });

            // 定期移除广告
            setInterval(removeAds, 1000);

            // 初始移除
            setTimeout(removeAds, 500);
            setTimeout(removeAds, 1000);
            setTimeout(removeAds, 2000);
            setTimeout(removeAds, 3000);
            setTimeout(removeAds, 5000);

            console.log('Ad block script injected');
        })();
        """

        let userScript: WKUserScript!
        if #available(iOS 14.0, *) {
            userScript = WKUserScript(source: jsCode, injectionTime: .atDocumentStart, forMainFrameOnly: false, in: .defaultClient)
        } else {
            userScript = WKUserScript(source: jsCode, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        }
        webView.configuration.userContentController.addUserScript(userScript)
    }

    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "videoSourceCaptured" {
            if let dict = message.body as? [String: Any],
               let url = dict["url"] as? String,
               let type = dict["type"] as? String {
                let quality = dict["quality"] as? String
                let title = dict["title"] as? String
                let pageURL = dict["pageURL"] as? String

                let source = VideoSource(url: url, type: type, quality: quality, title: title, pageURL: pageURL)

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if !self.capturedSources.contains(where: { $0.url == source.url }) {
                        self.capturedSources.append(source)
                    }
                }
            }
        }
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.progress = 1.0
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
            self.currentPageURL = webView.url?.absoluteString ?? ""
            self.pageTitle = webView.title ?? "视频"
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "无法访问该网站，请检查网络连接"
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil || !navigationAction.targetFrame!.isMainFrame {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
        }
        return nil
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    // MARK: - Public Methods
    func loadInitialURL() {
        guard let url = URL(string: homeURL) else { return }
        let request = URLRequest(url: url)
        webView?.load(request)
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        errorMessage = nil
        webView?.reload()
    }

    func goHome() {
        guard let url = URL(string: homeURL) else { return }
        let request = URLRequest(url: url)
        webView?.load(request)
    }

    func clearCapturedSources() {
        capturedSources.removeAll()
    }
}
