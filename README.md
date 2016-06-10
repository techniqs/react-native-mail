# react-native-mail

A React Native wrapper for Apple's ``MFMailComposeViewController`` from iOS and Mail Intent on android
Supports emails with attachments.

### Installation

```bash
npm i --save react-native-mail
```

### Add it to your android project

* In `android/setting.gradle`

```gradle
...
include ':RNMail', ':app'
project(':RNMail').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-mail/android')
```

* In `android/app/build.gradle`

```gradle
...
dependencies {
    ...
    compile project(':RNMail')
}
```

* register module (in MainActivity.java)

```java
import com.chirag.RNMail.*;  // <--- import

public class MainActivity extends Activity implements DefaultHardwareBackBtnHandler {
  ......

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    mReactRootView = new ReactRootView(this);

    mReactInstanceManager = ReactInstanceManager.builder()
      .setApplication(getApplication())
      .setBundleAssetName("index.android.bundle")
      .setJSMainModuleName("index.android")
      .addPackage(new MainReactPackage())
      .addPackage(new RNMail())              // <------ add here
      .setUseDeveloperSupport(BuildConfig.DEBUG)
      .setInitialLifecycleState(LifecycleState.RESUMED)
      .build();

    mReactRootView.startReactApplication(mReactInstanceManager, "ExampleRN", null);

    setContentView(mReactRootView);
  }

  ......

}
```

### Add it to your iOS project

1. Run `npm install react-native-mail --save`
2. Open your project in XCode, right click on `Libraries` and click `Add
   Files to "Your Project Name"` [(Screenshot)](http://url.brentvatne.ca/jQp8) then [(Screenshot)](http://url.brentvatne.ca/1gqUD).
3. Add `libRNMail.a` to `Build Phases -> Link Binary With Libraries`
   [(Screenshot)](http://url.brentvatne.ca/17Xfe).
4. Whenever you want to use it within React code now you can: `var Mailer = require('NativeModules').RNMail;`


## Example
```javascript
var Mailer = require('NativeModules').RNMail;

var MailExampleApp = React.createClass({
  handleHelp: function() {
    Mailer.mail({
      subject: 'need help',
      recipients: ['support@example.com'],
      body: '',
      attachment: {
        path: '',  // The absolute path of the file from which to read data.
        type: '',   // Mime Type: jpg, png, doc, ppt, html, pdf
        name: '',   // Optional: Custom filename for attachment
      }
    }, (error, event) => {
        if(error) {
          AlertIOS.alert('Error', 'Could not send mail. Please send a mail to support@example.com');
        }
    });
  },  
  render: function() {
    return (
      <TouchableHighlight
            onPress={row.handleHelp}
            underlayColor="#f7f7f7">
	      <View style={styles.container}>
	        <Image source={require('image!announcement')} style={styles.image} />
	      </View>
	   </TouchableHighlight>
    );
  }
});
```

### Note
On android callback will only have error(if any) as the argument. event is not available on android.

## Here is how it looks:
![Demo gif](https://github.com/chirag04/react-native-mail/blob/master/screenshot.jpg)

# API Modifications

* Added Android HTML support
* Added support for multiple attachments on iOS and Android.
* Added auto-detect mime type from common file extensions.

| Feature                  | iOS    | Android                                                                   |
| ------------------------ |--------| ------------------------------------------------------------------------- |
| HTML                     | Yes    | Yes - HTML support is **very** primitive.  No table support.              |
| Multiple file attachments| Yes    | Yes                                                                       | 

  
| mail          | Type                                    | Comment                                   |
| ------------- | --------------------------------------- | ----------------------------------------- |
| subject       | string        		          |                                           |
| recipients    | array of email address strings          |                                           |
| body          | string                                  | HTML is supported. Android is very basic. |  
| isHtml        | bool                                    | Set true if your body text contains HTML. |  
| attachmentList| array of one or more attachment objects |                                           |  
  

| attachmentList| Type   | Comment                                                                   |
| ------------- |--------| ------------------------------------------------------------------------- |
| path          | string | Absolute path to file                                                     |
| name          | string | Name to display as file atatchment. Not needed, name is derived from path | 
| mimeType      | string | Mime type. Not needed, mime is derived from file extension                |  

  
Example: Create attachmentList 
```
          let attachmentList = [];
          for(let i = 0; i < this.state.fileAttachmentList.length; ++i) {
            attachmentList.push({
              path: this.state.fileAttachmentList[i].fileNamePath,
              name: this.state.fileAttachmentList[i].fileName,
              mimeType: this.state.fileAttachmentList[i].fileMimeType,
            });
          }
```
* Added isHtml - Android HTML is awful ( no table, ol, etc. )
```
          Mailer.mail({
            subject: 'A great investment opportunity",
            recipients: ['john@acme.com', 'bob@acme.com'],
            body: '<h1>Greetings</h1>Hello John and Bob<br>Send money?<br><b>Goodbye</b>',
            isHtml: true,
            attachmentList: attachmentList,
          }, (error, event) => {
            if(error) {
              Alert.alert('Error', 'Could not send mail');
            }
          });
```

On Android, HTML email body results are awful as only *very* basic tags are supported.

Is there really no way to make it work like iOS?
* http://blog.iangclifton.com/2010/05/17/sending-html-email-with-android-intent/
* http://www.nowherenearithaca.com/2011/10/some-notes-for-sending-html-email-in.html
