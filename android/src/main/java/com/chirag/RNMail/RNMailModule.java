package com.chirag.RNMail;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.text.Html;
import android.util.Log;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.Callback;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
* NativeModule that allows JS to open emails sending apps chooser.
*/

public class RNMailModule extends ReactContextBaseJavaModule {
  private static final String TAG = RNMailModule.class.getSimpleName();

  ReactApplicationContext reactContext;

  public RNMailModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "RNMail";
  }

  @ReactMethod
  public void mail(ReadableMap options, Callback callback) {
    try {
      Log.d(TAG, "***********" );
      Log.d(TAG, "RNMail:mail" );
      Log.d(TAG, "***********" );

      String intentAction = Intent.ACTION_SENDTO;
      ArrayList<Uri> fileAttachmentUriList = getFileAttachmentUriList(options);
      if (1 <= fileAttachmentUriList.size()) {
        intentAction = Intent.ACTION_SEND_MULTIPLE;
      }

      Intent intent = new Intent(intentAction);
      intent.setData(Uri.parse("mailto:"));

      if (hasKeyAndDefined(options, "subject")) {
        intent.putExtra(Intent.EXTRA_SUBJECT, options.getString("subject"));
      }

      // On Android HTML email body results are awful, no <table>,<ol>,etc.
      // Is there really no way to make it work like iOS?
      // http://blog.iangclifton.com/2010/05/17/sending-html-email-with-android-intent/
      // http://www.nowherenearithaca.com/2011/10/some-notes-for-sending-html-email-in.html
      boolean isHtml = false;
      if (hasKeyAndDefined(options, "isHtml")) {
        isHtml = options.getBoolean("isHtml");
      }

      if (hasKeyAndDefined(options, "body")) {
        if(isHtml) {
          intent.putExtra(Intent.EXTRA_TEXT, Html.fromHtml(options.getString("body")));
        } else {
          intent.putExtra(Intent.EXTRA_TEXT, options.getString("body"));
        }
      }

      if (hasKeyAndDefined(options, "recipients")) {
        ReadableArray r = options.getArray("recipients");
        int length = r.size();
        String[] recipients = new String[length];
        for (int keyIndex = 0; keyIndex < length; keyIndex++) {
          recipients[keyIndex] = r.getString(keyIndex);
        }
        intent.putExtra(Intent.EXTRA_EMAIL, recipients);
      }

      if (1 <= fileAttachmentUriList.size()) {
        // If multiple attachments setType("plain/text"), else queryIntentActivities fails
        intent.setType("plain/text");
        intent.putExtra(Intent.EXTRA_STREAM, fileAttachmentUriList);
      }

      PackageManager manager = reactContext.getPackageManager();
      List<ResolveInfo> list = manager.queryIntentActivities(intent, 0);
      if (list == null || list.size() == 0) {
        callback.invoke("not_available");
        return;
      }

      Intent chooser = Intent.createChooser(intent, "Send Mail");
      chooser.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
      reactContext.startActivity(chooser);

    } catch (Exception ex) {
      Log.d(TAG, "RNMail:mail exception:");
      callback.invoke("error RNMail:mail");
    }
  }

  /**
  * Checks if a given key is valid
  * @param @{link ReadableMap} readableMap
  * @param @{link String} key
  * @return boolean representing whether the key exists and has a value
  */
  private Boolean hasKeyAndDefined(ReadableMap readableMap, String key) {
    return readableMap.hasKey(key) && !readableMap.isNull(key);
  }
  /**
  * Returned list is empty if no attachments foiund
  * @param @{link ReadableMap} options
  * @return ArrayList<Uri> containing file attachment Uri list
  */
  private ArrayList<Uri> getFileAttachmentUriList(ReadableMap options) {
    ArrayList<Uri> fileAttachmentUriList = new ArrayList<Uri>();
    if (hasKeyAndDefined(options, "attachmentList")) {
      ReadableArray attachmentList = options.getArray("attachmentList");
      int length = attachmentList.size();

      for(int i = 0; i < length; ++i) {
        Log.d(TAG, String.format("attachmentItem[%d]", i));
        ReadableMap attachmentItem = attachmentList.getMap(i);
        String fileName = "";
        String path = "";
        String mimeType = "";
        if (hasKeyAndDefined(attachmentItem, "fileName")) {
          fileName = attachmentItem.getString("fileName");
        }
        if (hasKeyAndDefined(attachmentItem, "path")) {
          path = attachmentItem.getString("path");
        }
        if (hasKeyAndDefined(attachmentItem, "mimeType")) {
          fileName = attachmentItem.getString("mimeType");
        }
        Log.d(TAG, String.format("fileName....: %s", fileName));
        Log.d(TAG, String.format("path: %s", path));
        Log.d(TAG, String.format("mimeType: %s", mimeType));
        boolean fileExists = new File(path).exists();
        Log.d(TAG, "fileExists:" + fileExists);
        if (fileExists) {
          fileAttachmentUriList.add(Uri.parse("file://" + path));
        }
      }
    }
    return fileAttachmentUriList;
  }


}
