FUNCTION mjd2hopkinsdate, hjd
 return, string(hjd, format='(F9.3)') + ' = ' + date_conv(hjd+2400000.5d - 7.0/24.0, 'S') + ' MST'
END