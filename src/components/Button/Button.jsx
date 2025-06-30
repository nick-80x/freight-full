const Button = ({ children, onClick, className, disabled }) => {
  return (
    <button 
      onClick={onClick}
      className={className}
      disabled={disabled}
    >
      {children}
    </button>
  );
};

export default Button;