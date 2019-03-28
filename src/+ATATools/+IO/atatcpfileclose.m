function y = atatcpfileclose( fd )
%atatcpfileclose closes file descriptor of ata data structure
%   y = atatcpfileclose( fd ) closes associated file descriptor

y = fclose(fd.fh);

end

