# Third-party files of the date range widget

Unmodified copies of the npm packages below. `../../js/daterange/DateRangePickerLoader.js`
loads the two scripts on demand, and `../../js/daterange/DateRangeWidget.scss` inlines the
stylesheet. They live here, outside `js/`, because the GBC build imports every `js/**/*.js` at
startup.

| File | Package | npm tarball integrity | SHA-256 of the file |
| ---- | ------- | --------------------- | ------------------- |
| `jquery.min.js` | jquery 3.7.1, `dist/jquery.min.js` | `sha512-m4avr8yL8kmFN8psrbFFFmB/If14iN5o9nw/NgnnM+kybDJpRsAynV2BsfpTYrTRysYUdADVD7CkUUizgkpLfg==` | `fc9a93dd241f6b045cbff0481cf4e1901becd0e12fb45166a8f17f95823f0b1a` |
| `daterangepicker.js` | daterangepicker 3.1.0 | `sha512-DxWXvvPq4srWLCqFugqSV+6CBt/CvQ0dnpXhQ3gl0autcIDAruG1PuGG3gC7yPRNytAD1oU1AcUOzaYhOawhTw==` | `88e56cd45cad3db88fdc772786d14cce8d0cc1879bc03e4e56be919dfd9ad229` |
| `daterangepicker.css` | daterangepicker 3.1.0 | (same tarball) | `94fdb66ec8fe748981a4f2090fdf4a2a0a3dbe5ace2e65c4ce46e95d692bdac7` |

Licenses: both MIT. jQuery's license is in `jquery-LICENSE.txt` (copied from the package) and
in the header of `jquery.min.js`. daterangepicker ships no license file; its MIT license is
stated in the header of `daterangepicker.js` and in its `package.json`.

Why these versions: daterangepicker 3.1.0 has been stable since 2020. 4.0.1 and 4.0.2 appeared
on 2026-11-08, after six years without a release, and were too recent to adopt without a
review. daterangepicker 3.x predates jQuery 4, which removed APIs, so jQuery stays on 3.7.1.

## Checking or refreshing the files

`npm pack` downloads a tarball and prints its integrity, which must match the table:

```
mkdir /tmp/drp && cd /tmp/drp
npm pack jquery@3.7.1 daterangepicker@3.1.0
tar -xzf jquery-3.7.1.tgz package/dist/jquery.min.js package/LICENSE.txt
shasum -a 256 package/dist/jquery.min.js
tar -xzf daterangepicker-3.1.0.tgz package/daterangepicker.js package/daterangepicker.css
shasum -a 256 package/daterangepicker.js package/daterangepicker.css
```

To move to another version, copy the new files here, update this table, and run the widget's
browser checks again.
